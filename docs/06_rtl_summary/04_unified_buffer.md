# 统一缓冲区 (unified_buffer.sv)

## 模块定位
TPU 的中央数据存储与调度单元，存储所有矩阵数据（输入、权重、偏置、标签等），按指令向各子系统分发数据。

## 存储结构
- `ub_memory[0:127]`：128 × 16-bit 的片上 SRAM，行主序存储
- 所有矩阵共享同一块存储空间，通过指针区分

## 7 种读取模式（ub_ptr_select）
| 编号 | 模式 | 目标 | 说明 |
|------|------|------|------|
| 0 | Input | Systolic 左侧 | 激活矩阵，支持转置读取 |
| 1 | Weight | Systolic 顶部 | 权重矩阵，支持转置，反向跳跃读取 |
| 2 | Bias | VPU bias 模块 | 偏置向量，按列广播 |
| 3 | Y | VPU loss 模块 | 真实标签矩阵 |
| 4 | H | VPU lr_d 模块 | 激活输出（用于反向传播） |
| 5 | Grad_Bias | gradient_descent | 偏置梯度下降 |
| 6 | Grad_Weight | gradient_descent | 权重梯度下降 |

## 写入逻辑
- **Host 写入**：外部通过 `ub_wr_host_data_in` 加载初始参数
- **VPU 写回**：VPU 计算结果通过 `ub_wr_data_in` 写回
- **梯度更新写回**：gradient_descent 模块更新后的权重/偏置写回
- 写入顺序：for 循环递减以保证行主序存储

## 读取调度机制
每种读取模式独立维护：
- `rd_xxx_ptr`：当前读取指针
- `rd_xxx_row_size / col_size`：矩阵维度
- `rd_xxx_time_counter`：脉动时间计数器（控制对角线馈入时序）

### 脉动馈入时序
```
time=0: data[0] → port[0]
time=1: data[1] → port[0], data[2] → port[1]  (对角线展开)
time=2: data[3] → port[1]
```
条件：`time_counter >= i && time_counter < row_size + i && i < col_size`

## 转置读取
- Input 转置：for 循环方向翻转（递增 vs 递减）
- Weight 转置：指针跳跃方向改变，`rd_weight_skip_size` 控制步长

## 内嵌 Gradient Descent
- 通过 `generate` 实例化 `SYSTOLIC_ARRAY_WIDTH` 个 gradient_descent 模块
- `grad_bias_or_weight` 区分偏置更新（累积式）和权重更新（逐元素）
- 梯度有效信号由 `always_comb` 自动判断计数器状态

## 修复的 Bug
- 读取命令初始化从 `always_comb` 迁移到 `always_ff`，修复多驱动竞争条件
- 混用阻塞/非阻塞赋值（已知问题，`wr_ptr` 等使用阻塞赋值 `=`）

## 简历话术
> 实现了 Unified Buffer 统一缓冲区，支持 7 种读取模式和转置读取，通过脉动时序调度实现对角线数据馈入。内嵌梯度下降模块支持在线参数更新。修复了读取命令初始化的竞争条件 Bug。
