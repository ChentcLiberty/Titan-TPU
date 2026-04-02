# TPU 顶层模块 (tpu.sv)

## 模块定位
TPU 顶层模块，整个加速器的最高层次封装，负责连接三大核心子系统，无自身计算逻辑，纯结构化互连。

## 整体架构图
```
                        ┌─────────────────────────────────────────────────────┐
                        │                    TPU Top                          │
  Host Interface        │                                                     │
  ──────────────────────┤                                                     │
  ub_wr_host_data_in[2] │   ┌──────────────┐    ┌──────────┐    ┌─────────┐  │
  ub_wr_host_valid_in[2]│   │              │    │          │    │         │  │
  ub_rd_start_in        │──→│   Unified    │──→ │ Systolic │──→ │   VPU   │  │
  ub_rd_transpose       │   │   Buffer     │    │  Array   │    │         │  │
  ub_ptr_select[8:0]    │   │   (ub_inst)  │    │  2×2     │    │ Bias    │  │
  ub_rd_addr_in[15:0]   │   │              │←──────────────────│ ReLU    │  │
  ub_rd_row_size[15:0]  │   │  128×16bit   │    │  4×PE    │    │ Loss    │  │
  ub_rd_col_size[15:0]  │   │  SRAM        │    │          │    │ ReLU'   │  │
  learning_rate_in[15:0]│   └──────────────┘    └──────────┘    └─────────┘  │
  vpu_data_pathway[3:0] │         ↑ bias/Y/H 直连 VPU ──────────────┘        │
  sys_switch_in         │                                                     │
  vpu_leak_factor_in    │                                                     │
  inv_batch_size_×2_in  │                                                     │
                        └─────────────────────────────────────────────────────┘
```

## 参数
| 参数 | 默认值 | 含义 | 影响 |
|------|--------|------|------|
| SYSTOLIC_ARRAY_WIDTH | 2 | 脉动阵列宽度 | 决定 PE 数量(N²)、UB 端口数、VPU 并行度 |

修改此参数可扩展为 4×4、8×8 等更大阵列，但需要同步修改 systolic.sv 中的手动 PE 连线。

## 三大子系统及其连接

### 1. Unified Buffer → Systolic Array
```
时序：UB 按脉动时序逐拍输出 → Systolic 左侧/顶部接收

UB output port              →  Systolic input port
─────────────────────────────────────────────────────
ub_rd_input_data_out_0      →  sys_data_in_11        (Row 1 左侧输入)
ub_rd_input_data_out_1      →  sys_data_in_21        (Row 2 左侧输入)
ub_rd_input_valid_out_0     →  sys_start             (启动信号，仅用 port0)
ub_rd_weight_data_out_0     →  sys_weight_in_11      (Col 1 顶部权重)
ub_rd_weight_data_out_1     →  sys_weight_in_12      (Col 2 顶部权重)
ub_rd_weight_valid_out_0    →  sys_accept_w_1        (Col 1 权重加载使能)
ub_rd_weight_valid_out_1    →  sys_accept_w_2        (Col 2 权重加载使能)
ub_rd_col_size_out          →  ub_rd_col_size_in     (列数，用于动态 PE 使能)
ub_rd_col_size_valid_out    →  ub_rd_col_size_valid_in
```

### 2. Systolic Array → VPU
```
时序：Systolic 底部输出（延迟数拍后）→ VPU 接收

Systolic output port        →  VPU input port
─────────────────────────────────────────────────────
sys_data_out_21             →  vpu_data_in_1         (Col 1 累加结果)
sys_data_out_22             →  vpu_data_in_2         (Col 2 累加结果)
sys_valid_out_21            →  vpu_valid_in_1
sys_valid_out_22            →  vpu_valid_in_2
```

### 3. VPU → Unified Buffer（写回环路）
```
关键：VPU 输出通过内部 wire 连接到 UB 的写入端口，形成闭环

vpu_data_out_1  → ub_wr_data_in[0]    (assign 直连)
vpu_data_out_2  → ub_wr_data_in[1]    (assign 直连)
vpu_valid_out_1 → ub_wr_valid_in[0]   (assign 直连)
vpu_valid_out_2 → ub_wr_valid_in[1]   (assign 直连)
```
这是 tpu.sv 中唯一的逻辑：4 条 assign 语句完成 VPU→UB 写回连接。

### 4. UB → VPU 直连（旁路 Systolic）
```
这些数据不经过 Systolic Array，直接从 UB 送到 VPU 的子模块：

ub_rd_bias_data_out_0/1     →  bias_scalar_in_1/2    (偏置标量)
ub_rd_Y_data_out_0/1        →  Y_in_1/2              (真实标签)
ub_rd_H_data_out_0/1        →  H_in_1/2              (缓存激活值)
```

## 完整数据流时序（前向推理一次矩阵乘法）

```
Cycle   UB                  Systolic            VPU              UB Write
──────────────────────────────────────────────────────────────────────────
  1     加载 Weight W11     PE11 接收 W11       idle             idle
  2     加载 Weight W12     PE12 接收 W12       idle             idle
  3     Switch 信号         W copy to active    idle             idle
  4     输出 Input X11      PE11: X11×W11       idle             idle
  5     输出 X12,X21        PE11→PE12 传播      idle             idle
        (对角线馈入)        PE21: X21×W11+psum
  6     输出 X22            PE22 计算完成        idle             idle
  7     idle                Out21 有效           Bias+ReLU(Out21) idle
  8     idle                Out22 有效           Bias+ReLU(Out22) 写回 H[0]
  9     idle                idle                 完成             写回 H[1]
```

注意：实际时序取决于矩阵大小和 UB 的脉动调度，上图为 2×2 矩阵的简化示意。

## 外部接口完整列表

### 输入信号
| 信号 | 位宽 | 说明 | 连接目标 |
|------|------|------|----------|
| clk | 1 | 全局时钟 | 所有子模块 |
| rst | 1 | 异步高有效复位 | 所有子模块 |
| ub_wr_host_data_in | [15:0]×2 | Host 写入数据 | UB |
| ub_wr_host_valid_in | 1×2 | Host 写入有效 | UB |
| ub_rd_start_in | 1 | 读取命令启动 | UB |
| ub_rd_transpose | 1 | 转置读取使能 | UB |
| ub_ptr_select | [8:0] | 读取模式（0-6） | UB |
| ub_rd_addr_in | [15:0] | 读取起始地址 | UB |
| ub_rd_row_size | [15:0] | 矩阵行数 | UB |
| ub_rd_col_size | [15:0] | 矩阵列数 | UB |
| learning_rate_in | [15:0] | 学习率 Q8.8 | UB→gradient_descent |
| vpu_data_pathway | [3:0] | VPU 通路控制 | VPU |
| sys_switch_in | 1 | 权重双缓冲切换 | Systolic |
| vpu_leak_factor_in | [15:0] | LeakyReLU α | VPU |
| inv_batch_size_times_two_in | [15:0] | 2/N 系数 | VPU→loss |

### 输出信号
无。TPU 顶层没有输出端口，所有计算结果存储在 UB 内部，需要通过 Host 接口读回（当前版本未实现 Host 读取端口）。

## IC 设计关键知识点

### 1. 顶层互连设计原则
- tpu.sv 是纯结构化模块，**零逻辑**（仅 4 条 assign），所有计算在子模块内完成
- 这是 SoC 设计的标准做法：顶层只做连线，不做逻辑
- 好处：综合工具可以独立优化每个子模块的时序

### 2. 数据环路与时序收敛
```
UB → Systolic → VPU → UB（写回）
```
这是一个**数据环路**，但不是组合环路（每个子模块内部都有寄存器打断）。面试中可能被问到：
- Q: "这个环路会不会导致时序问题？"
- A: "不会。每个子模块输出都经过寄存器，环路被时序逻辑打断。UB 写入和读取是不同时钟周期的独立操作。"

### 3. 参数化扩展性
当前 `SYSTOLIC_ARRAY_WIDTH=2` 只传递给了 UB，systolic.sv 内部是手动连线 4 个 PE。要真正参数化需要：
- systolic.sv 改为 generate 循环实例化
- tpu.sv 的端口改为数组形式
- 这是一个可以在面试中主动提出的**改进方向**

### 4. 缺失的功能（面试中主动提及）
- 无 Host 读取端口（计算结果无法读回）
- 无指令存储器（control_unit 未集成到 tpu.sv）
- 无 AXI/APB 总线接口（规划中）
- 无时钟门控（功耗优化方向）

## 简历话术
> 设计了 TPU 顶层架构，采用纯结构化互连将 Unified Buffer（128×16bit SRAM）、2×2 Weight Stationary Systolic Array、VPU（4级后处理流水线）三大子系统通过数据环路连接。支持前向推理（1100通路）和反向训练（0001通路）两种工作模式，VPU 输出写回 UB 形成闭环数据流。

## 面试高频问题
- **Q: 为什么顶层不做任何逻辑？**
  A: SoC 设计规范，顶层只做互连，便于模块独立综合和时序约束。
- **Q: 数据环路怎么保证不死锁？**
  A: 读写操作由外部指令序列控制，不存在自触发的反馈环。每步操作都是 Host 发起的显式命令。
- **Q: 如何扩展到更大的阵列？**
  A: 修改 SYSTOLIC_ARRAY_WIDTH 参数，同时将 systolic.sv 改为 generate 循环，UB 端口改为参数化数组。
