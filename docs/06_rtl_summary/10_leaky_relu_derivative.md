# LeakyReLU 导数模块 (leaky_relu_derivative_child.sv / leaky_relu_derivative_parent.sv)

## 模块定位
VPU 第四级处理，计算激活函数导数并与上游梯度相乘，完成 dL/dZ = dL/dH × LeakyReLU'(H)，是反向传播链的关键环节。

## 层次关系
```
leaky_relu_derivative_parent（顶层，2路并行）
  ├── leaky_relu_derivative_child col_1（第1列）
  └── leaky_relu_derivative_child col_2（第2列）
```

## child 内部结构
```
lr_d_data_in (dL/dH) ──→ [fxp_mul × leak_factor] ──→ mul_out
                                                         ↓
lr_d_H_data_in (H) ──→ [MUX: H >= 0 ?] ──→ [寄存器] ──→ lr_d_data_out
                          ↑ yes: pass through dL/dH
                          ↑ no:  mul_out (α × dL/dH)
```

## 数学定义
```
dL/dZ = dL/dH × 1       (H >= 0，导数为1)
dL/dZ = dL/dH × α       (H < 0，导数为α)
```

## 与 LeakyReLU 前向的区别
| | 前向 (leaky_relu_child) | 导数 (leaky_relu_derivative_child) |
|---|---|---|
| 判断依据 | `lr_data_in >= 0`（Z本身） | `lr_d_H_data_in >= 0`（缓存的H） |
| 乘法对象 | Z × α | dL/dH × α |
| 额外输入 | 无 | H 矩阵（来自 UB 或 VPU 缓存） |

## H 数据来源
- **过渡模式（1111）**：使用 VPU 内部缓存的 `last_H_data`
- **反向模式（0001）**：从 UB 的 H 端口读取

## 接口
| 信号 | 说明 |
|------|------|
| lr_d_data_in [15:0] | 上游梯度 dL/dH |
| lr_d_H_data_in [15:0] | 激活输出 H（用于判断正负） |
| lr_leak_factor_in [15:0] | 泄漏因子 α |
| lr_d_data_out [15:0] | 输出梯度 dL/dZ |

## 简历话术
> 实现了 LeakyReLU 导数模块，根据缓存的前向激活值 H 的符号选择梯度直通或缩放，支持过渡模式（使用 VPU 内部 H 缓存）和反向模式（从 UB 读取 H）两种数据源。
