# MSE 损失梯度模块 (loss_child.sv / loss_parent.sv)

## 模块定位
VPU 第三级处理，计算 MSE 损失函数对激活输出的梯度 dL/dH = (2/N)(H - Y)，用于反向传播。

## 层次关系
```
loss_parent（顶层，2路并行）
  ├── loss_child first_column（第1列）
  └── loss_child second_column（第2列）
```

## loss_child 内部结构
```
H_in ──→ [fxp_addsub (H-Y)] ──→ diff_stage1 ──→ [fxp_mul × 2/N] ──→ final_gradient ──→ [寄存器] ──→ gradient_out
Y_in ──→ [fxp_addsub]                             ↑
                                    inv_batch_size_times_two_in
```

## 数学定义
```
MSE Loss = (1/N) Σ(H - Y)²
dL/dH = (2/N)(H - Y)
```

## 两级组合逻辑流水
1. **Stage 1**：`fxp_addsub` 计算差值 `diff = H - Y`（sub=1）
2. **Stage 2**：`fxp_mul` 计算 `gradient = diff × (2/N)`
3. **寄存输出**：`always_ff` 寄存一拍

## 接口
| 信号 | 说明 |
|------|------|
| H_in [15:0] | 激活输出（来自 LeakyReLU） |
| Y_in [15:0] | 真实标签（从 UB 读取） |
| inv_batch_size_times_two_in [15:0] | 2/N 系数（Q8.8 定点） |
| gradient_out [15:0] | MSE 梯度 dL/dH |

## loss_parent 角色
- 纯结构化封装，实例化 2 个 loss_child
- 共享 `inv_batch_size_times_two_in`

## 简历话术
> 实现了 MSE 损失梯度计算模块，两级组合逻辑完成减法和缩放运算，输出 dL/dH 梯度用于反向传播链路。
