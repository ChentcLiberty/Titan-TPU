# TinyTPU AXI SoC E2E 调试总结

**日期**：2026-03-31
**分支**：master
**关键文件**：`_vendor/tiny-tpu/src_axi/`, `_vendor/tiny-tpu/compiler/`, `_vendor/tiny-tpu/test/test_tpu_soc_axil_e2e.py`

---

## 目标

通过 AXI-Lite 接口驱动 `tpu_soc` 完成 2 层 MLP forward pass，验证 H1 输出与 Python 参考模型一致。

---

## 最终结果

```
Sequencer done after ~0 cycles
PASS H1[0,0]: exp=-0.2461 got=-0.2461
PASS H1[1,0]: exp=-0.5352 got=-0.5352
PASS H1[2,0]: exp=-0.0977 got=-0.0977
PASS H1[3,0]: exp=-0.3867 got=-0.3867
PASS H1[0,1]: exp=0.1875  got=0.1875
FAIL H1[1,1]: exp=0.6094  got=0.2773  ← 已知 RTL bug
PASS H1[2,1]: exp=0.2773  got=0.2773
FAIL H1[3,1]: exp=0.6992  got=0.3672  ← 已知 RTL bug
=== Scoreboard: 6/8 PASS ===
```

**6/8 PASS，与原始 `test_tpu_verify` testbench 结果完全一致。**
2 个 FAIL 是已知的 RTL col2 时序偏移 bug（见下文），与 AXI 接口无关。

---

## 调试过程：按根因分类

### Bug 1：Icarus VPI 无法读取 unpacked array port

**现象**：`ub_wr_host_valid` wire 在 cocotb 里读出全 X，UB `wr_ptr` 永远是 0，push 无效。
**根因**：Icarus Verilog 对 `output logic [0:N-1]` 形式的 unpacked array port 的 `assign` 驱动有 bug，仿真器内部值永远是 X。
**修复**：
- `tpu_frontend_axil.sv`：端口改为独立 scalar（`ub_wr_host_valid_out_0/1`，`ub_wr_host_data_out_0/1`）
- `tpu_soc.sv`：声明 scalar wire，再用 `assign` 填到 unpacked array 传给 `tpu.sv`

### Bug 2：`control_unit` always_comb part-select 导致 X 传播

**现象**：Icarus 报 7 个 `sorry: constant selects in always_* not supported`，`cu_ub_valid` 输出全 X。
**根因**：Icarus 对 `always_comb` 块内的 `instruction[18:3]` 等 part-select 处理有 bug。
**修复**：把所有 part-select 提取为模块顶层的 `assign` 中间信号（`f_addr`、`f_row`、`f_wrdata` 等），`always @(*)` 里只引用这些信号。

### Bug 3：SWITCH 指令时序错误

**现象**：systolic array 输出全 0（权重未切换），VPU 无有效输出。
**根因**：scheduler 原来的顺序是 `load_w1 → stream_x → SWITCH`，sequencer 在 `stream_x` 后等 vpu_drain 才 dispatch SWITCH，但此时权重还是 0（初始值）。
**修复**：调整为 `load_w1 → NOP×4 → SWITCH → stream_x`。NOP×4 等权重完全 feed 进 PE shadow 寄存器，SWITCH 后 stream_x 才开始驱动 systolic。所有 layer（forward、backward、weight update）均做相同调整。

### Bug 4：`vpu_data_pathway` 不持久

**现象**：H1 col2 缺失，systolic 输出经过 VPU 时 pathway=0（全关），lane2 无输出。
**根因**：`control_unit` 的 `vpu_data_pathway` 只在 `seq_instr_pulse=1`（dispatch 那一拍）有效，其他时间指令为 0，pathway 归零。但 systolic 输出要在 dispatch 后若干 cycle 才到达 VPU。
**修复**：在 `tpu_frontend_axil` 加 `vpu_pathway_reg`，在每次 UB_RD dispatch 时 latch `seq_instr[22:19]`，用寄存器持续驱动 `vpu_data_pathway_out`。

### Bug 5：`needs_wait` 逻辑消耗了错误的 vpu_drain

**现象**：sequencer 在 `load_old_b2`（ptr_sel=5）处永久卡死，vpu_drain 永不到来。
**根因**：原 `needs_wait = (ptr_sel==2 || ptr_sel==5 || ptr_sel==6)`，`stream_b2`（ptr_sel=2）也触发 wait，消耗了唯一一次 dZ2 drain，后续 `load_old_b2`（ptr_sel=5）再等就没有 drain 了。
**修复**：用 IMEM bit[23] 作为显式 `wait_after` 标记（`seq_needs_wait = seq_instr[23]`），只在确实需要等 VPU drain 的指令上置位：
  - `stream_b1`（等 H1 drain）
  - `load_old_b2`（等 dZ2 drain）
  - `load_old_b1`（等 dZ1 drain）
  - `load_old_w1/w2`（等 dW drain）

### Bug 6：scheduler 缺少 `vpu_path` 字段

**现象**：transition_layer2、backward_layer1 的 VPU pathway=0，计算错误。
**根因**：`scheduler.py` 里多个 `_ub_read()` 调用缺少 `vpu_path=` 参数。
**修复**：补全所有 UB_RD 指令的 vpu_path 字段，与 `test_tpu.py` 的 `vpu_data_pathway` 设置保持一致。

---

## 已知遗留 bug：H1 col2 时序偏移

**现象**：H1[:,1] 中第 2、4 个元素（index 1, 3）输出值约为期望值的一半（实为重复了上一个值）。
**根因**：2×2 systolic array 的 col1/col2 输出天然错开 1 cycle。UB 的 `rd_bias_time_counter` 驱动 bias read，其与 systolic 输出延迟不对齐，导致 B1[1] 在错误的时刻加到 col2 的数据流上，产生 stale 值。
**确认**：原始 `test_tpu_verify`（直接驱动 testbench）和 AXI e2e 测试均有相同的 2 个 FAIL，证明是 RTL 本身的问题，与 AXI 接口无关。
**后续**：需要修复 `unified_buffer_v3.sv` 里 bias read 的时序对齐逻辑。

---

## 架构变更总结

| 文件 | 变更 |
|------|------|
| `src_axi/tpu_frontend_axil.sv` | unpacked array port → scalar；vpu_pathway_reg；wait_after bit[23]；seq_needs_wait 改为 bit[23] |
| `src_axi/tpu_soc.sv` | unpacked array wire → scalar + assign bridge |
| `src_axi/control_unit.sv` | always_comb part-select → 顶层 assign 中间信号；always_comb → always @(*) |
| `compiler/scheduler.py` | SWITCH 移到 load_weight 之后（加 NOP×4）；补全 vpu_path；加 wait_after 标记 |
| `compiler/encode_instrs.py` | 支持 wait_after bit[23] 编码 |
| `test/test_tpu_soc_axil_e2e.py` | E2E cocotb 测试（AXI load + run + scoreboard） |
