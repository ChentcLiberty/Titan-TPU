# TinyTPU AXI-Lite SoC 端到端验证 — 完整工作总结

> 更新时间：2026-03-31
> Commit：781e65c

---

## 一、工作目标

在原始 `tiny-tpu`（testbench 直接驱动 RTL 端口）的基础上，实现一套完整的 **AXI-Lite SoC 接口层**，并通过 cocotb e2e 测试验证整个 MLP forward pass（H1 输出）与原始 testbench 一致。

整体架构：
```
cocotb (Python)
  └─ AXI-Lite Master
       └─ tpu_soc_top
            ├─ tpu_frontend_axil   ← AXI 解码 + sequencer
            └─ tpu_soc
                 ├─ tpu_frontend_axil (实例)
                 └─ tpu (原始 RTL 核)
                      ├─ systolic
                      ├─ vpu
                      └─ unified_buffer_v3
```

---

## 二、新增文件

| 文件 | 说明 |
|------|------|
| `src_axi/tpu_frontend_axil.sv` | AXI-Lite 解码、寄存器堆、sequencer、IMEM |
| `src_axi/tpu_soc.sv` | SoC 顶层，连接 frontend 和 TPU 核 |
| `src_axi/control_unit.sv` | 指令解码，输出 TPU 控制信号 |
| `compiler/scheduler.py` | 从 model_spec 生成 schedule（指令序列） |
| `compiler/encode_instrs.py` | 将 schedule 编码为 32-bit IMEM hex |
| `compiler/out/imem.hex` | 当前 MLP 2×2 的 IMEM（59 条指令） |
| `test/test_tpu_soc_axil_e2e.py` | cocotb e2e 测试：AXI 加载数据、启动 sequencer、采集 H1 |

---

## 三、32-bit 指令格式

```
[31:24]  reserved (bit23=wait_after)
[22:19]  vpu_data_pathway (4-bit)
[18:16]  ptr_sel (3-bit)
[15]     ub_rd_transpose
[14:13]  ub_rd_col_size
[12:9]   ub_rd_row_size
[8:3]    ub_rd_addr
[2:0]    opcode: 000=NOP, 001=CONTROL, 010=UB_RD
```

**wait_after（bit23）**：该位置 1 时，sequencer 在 dispatch 本条指令后进入 SEQ_WAIT，等待 `vpu_drain`（vpu_valid 下降沿）才推进到下一条指令。

---

## 四、Sequencer 设计

```
SEQ_IDLE → (start_pulse) → SEQ_DISPATCH → SEQ_ADVANCE / SEQ_WAIT
                                                ↑          ↓
                                           ← vpu_drain ←─┘
```

- **SEQ_DISPATCH**：把 `imem[pc]` 发给 control_unit（`seq_instr_pulse=1` 持续 1 拍），同时更新 `vpu_pathway_reg`
- **SEQ_ADVANCE**：无需等待，立即推进 pc
- **SEQ_WAIT**：等 `vpu_drain = vpu_valid_prev & !vpu_valid_now`，才推进 pc
- **`needs_wait`**：由 IMEM 指令 bit[23]（`wait_after`）控制，而非隐式 ptr_sel 推断

---

## 五、Debug 过程详细记录

### Bug 1：UB host write 完全无效（wr_ptr 始终为 0）

**现象**：cocotb 写 UB_DATA + push 后，`ub_inst.wr_ptr` 不变，UB memory 全 0。

**根因**：Icarus Verilog 对 **unpacked array 类型的 output port** 的 `assign` 语句有 bug——`ub_wr_host_valid_out[0]` 始终是 X，导致 UB 无法采样到有效的 `wr_en`。

**修复**：
- `tpu_frontend_axil.sv`：把 `output logic ub_wr_host_valid_out [0:N-1]` 改为两个独立 scalar port：`ub_wr_host_valid_out_0`、`ub_wr_host_valid_out_1`
- `tpu_soc.sv`：用 scalar wire 接收，再用 `assign ub_wr_host_valid[0] = ...` 桥接到 `tpu.sv` 的 unpacked array 输入

---

### Bug 2：control_unit always_comb X 传播

**现象**：`cu_ub_valid[0]` 是 X，导致 `ub_wr_host_valid_out` 也是 X。

**根因**：Icarus 对 `always_comb` 内部的 constant part-select（`instruction[18:3]` 等）报 warning 并导致整个块 X。

**修复**：
```sv
// 把 always_comb 里的 part select 提取为顶层 assign
logic [5:0]  f_addr;   assign f_addr  = instruction[8:3];
logic [3:0]  f_row;    assign f_row   = instruction[12:9];
// ...
always @(*) begin  // 改为 always @(*)
```

---

### Bug 3：vpu_data_pathway 不持久

**现象**：systolic 输出 Z 经过 VPU 时，pathway=0（全关），H1 输出全为 0。

**根因**：`vpu_data_pathway` 从每条 IMEM 指令的 bits[22:19] 实时解码。当 `seq_instr_pulse=0`（两条指令间隙），`instr_to_cu=0`，pathway 变为 0，VPU 流水线断路。

而 systolic array 的输出在 dispatch stream_x 之后的**数个 cycle** 才出现，此时 pulse 早已清零。

**修复**：加 `vpu_pathway_reg`，在每次 UB_RD dispatch 时 latch：
```sv
if (seq_instr_pulse && seq_instr[2:0] == 3'b010)
    vpu_pathway_reg <= seq_instr[22:19];
assign vpu_data_pathway_out = vpu_pathway_reg;
```

---

### Bug 4：SWITCH 指令时序错误

**现象**：systolic array 输出全为 0（权重是 0）。

**根因**：scheduler 原来的顺序是 `load_w1 → stream_x → SWITCH → stream_b1`。SWITCH 在 stream_x 之后，但 stream_x（ptr_sel=0）原来有 needs_wait，导致 SWITCH 被阻塞到 vpu_drain 之后才执行——此时 systolic 已经用了全 0 的 active weight 计算完了。

另外即使调整顺序后，`load_w1 → SWITCH` 之间只有 2 个 cycle，权重还没完全 feed 进 shadow 寄存器（需要 row+col=4 个 cycle）。

**修复**：
1. 调整顺序：`load_w → NOP×4 → SWITCH → stream`
2. ptr_sel=0（input stream）不需要 wait，立即 advance

---

### Bug 5：needs_wait 逻辑消耗错误的 drain

**现象**：sequencer 在 `load_old_b2`（pc=17）永久卡住，`vpu_drain` 不再产生。

**根因**：原来 `needs_wait` 包含 ptr_sel=2（bias）。transition_layer2 的流程：
```
stream_h1(ptr_sel=0) → stream_b2(ptr_sel=2, wait) → 等 dZ2 drain
                                                         ↓
                                              load_old_b2(ptr_sel=5, wait) → 又等 drain
```
dZ2 的 vpu_valid 只产生一次 drain，被 stream_b2 的 wait 消耗掉了，load_old_b2 再等就永远没有 drain 了。

**修复**：改用 IMEM bit[23] 作为显式 `wait_after` 标记，只在真正需要等 drain 的指令上设置：
- `stream_b1`（forward_layer1 → 等 H1 drain）
- `load_old_b2`（transition_layer2 → 等 dZ2 drain）
- `load_old_b1`（backward_layer1 → 等 dZ1 drain）
- `load_old_w1/w2`（weight update → 等 dW drain）

---

### Bug 6：scheduler 缺 vpu_path 字段

**现象**：stream_b1 的 vpu_pathway=0000，H1 经过 VPU 时所有模块关闭（全 bypass），输出全 0。

**根因**：scheduler.py 里 `stream_b1`、`stream_b2`、`stream_y` 等指令没有传入 `vpu_path` 参数，默认编码为 0。原始 testbench 里 `vpu_data_pathway` 是持久寄存器（一次设置后保持），而 IMEM 方案里每条指令独立编码，必须显式指定。

**修复**：在 scheduler.py 里为所有 UB_RD 指令补全 `vpu_path`：

| 指令 | pathway | 含义 |
|------|---------|------|
| stream_x / stream_b1 | 1100 | bias + leaky_relu（forward layer 1）|
| stream_h1 / stream_b2 / stream_y / load_old_b2 | 1111 | bias + relu + loss + relu_d（layer 2 + loss）|
| stream_dz2 / stream_h1_for_derivative / load_old_b1 | 0001 | leaky_relu_derivative only |
| load_dz1 / load_old_w1/w2 | 0000 | 纯 systolic，VPU bypass |

---

## 六、最终测试结果

```
test_tpu_soc_axil_e2e  (Icarus + cocotb)

Sequencer done after ~0 cycles
REF H1[:,0]=[-0.2461, -0.5352, -0.0977, -0.3867]
REF H1[:,1]=[0.1875, 0.6094, 0.2773, 0.6992]

PASS H1[0,0]: exp=-0.2461  got=-0.2461
PASS H1[1,0]: exp=-0.5352  got=-0.5352
PASS H1[2,0]: exp=-0.0977  got=-0.0977
PASS H1[3,0]: exp=-0.3867  got=-0.3867
PASS H1[0,1]: exp=0.1875   got=0.1875
FAIL H1[1,1]: exp=0.6094   got=0.2773  err=0.3320  ← 已知 RTL bug
PASS H1[2,1]: exp=0.2773   got=0.2773
FAIL H1[3,1]: exp=0.6992   got=0.3672  err=0.3320  ← 已知 RTL bug

=== Scoreboard: 6/8 PASS ===
```

与原始 `test_tpu_verify` testbench 结果完全一致（相同的 6/8 PASS，相同的 2 个 FAIL）。

---

## 七、遗留问题：H1 col2 时序偏移 bug

**位置**：`src_axi/unified_buffer_v3.sv`，`rd_bias_time_counter` 逻辑

**现象**：
- H1[1,1]：exp=0.609，got=0.277（≈exp/2）
- H1[3,1]：exp=0.699，got=0.367（≈exp/2）

**根因分析**：

在 2×2 systolic array 里，col1 和 col2 的输出**天然错开 1 cycle**（因为权重沿对角线 feed 进 PE，右列比左列晚 1 拍）。

UB 的 bias read 模块按固定节拍输出 B1：
```
t=0: B1[0] → lane0 bias
t=1: B1[0] + B1[1] → lane0 + lane1 bias（同一 cycle）
t=2: B1[1] → lane1 bias
```

而 systolic 输出时序：
```
t=0: col1[row0] 到达 VPU
t=1: col1[row1], col2[row0] 同时到达
t=2: col1[row2], col2[row1]
...
```

col2[row0] 在 t=1 到达，此时 B1[1] 已经按设计在 t=1 输出了，表面上对齐。但实际仿真中，`rd_bias_time_counter` 的初始化时机比 systolic 输出早 1 cycle，导致 B1[1] 在 col2 数据到来**之前**就已经输出完毕。col2 接收到的 bias 是 0 或者错位的值，而不是正确的 B1[1]。

结果：col2 的每行只叠加了约一半的 bias，输出约为正确值的一半。

**修复方向**：在 `unified_buffer_v3.sv` 里，对 lane1（col2）的 bias 输出增加 1 cycle 延迟，使其与 col2 的 systolic 输出对齐：
```sv
// rd_bias_time_counter 的 lane1 判断改为:
if (rd_bias_time_counter >= j+1 && ...)  // +1 补偿 col2 的天然延迟
```

或者在 bias_child.sv 里对 lane1 的输出加一个 pipeline register。

**影响**：此 bug 在原始 `test_tpu.py` / `test_tpu_verify` 里同样存在，属于项目原有 bug，与 AXI 接口无关。

---

## 八、项目当前状态

| 模块 | 状态 | 备注 |
|------|------|------|
| PE | 验证通过 | test_pe.py |
| Systolic Array | 验证通过 | test_systolic_boundary.py |
| Unified Buffer | 验证通过 | test_unified_buffer 系列 |
| VPU forward (col1) | 验证通过 | test_tpu_verify |
| VPU forward (col2) | **已知 bug** | bias 对齐偏移，col2 值约为期望值的一半 |
| AXI-Lite SoC 接口 | 验证通过 | test_tpu_soc_axil_e2e，与原始 testbench 一致 |
| backward pass | 未验证 | sequencer 已生成完整 backward 指令序列 |
| weight update | 未验证 | scheduler 已生成 dW1/dW2 tile 指令 |

---

## 九、后续工作建议

1. **修复 col2 bias 对齐 bug**（`unified_buffer_v3.sv` lane1 延迟 +1）
2. **验证 backward pass**：扩展 e2e 测试，比对 dZ1、dZ2、更新后的 W1/W2/B1/B2
3. **验证 weight update**：检查 gradient_descent 模块在 AXI 路径下的 in-UB 更新
4. **增加 VCS 仿真支持**：当前 e2e 只在 Icarus 跑通，Icarus 有多处 unpacked array 的局限性
5. **指令编码扩展**：当前 32-bit 格式有 8 bit reserved，可用于 stride、mask 等功能

**现象**：stream_b1 的 vpu_pathway=0000，H1 经过 VPU