# LeakyReLU 激活模块 (leaky_relu_child.sv / leaky_relu_parent.sv)

## 模块定位
VPU 第二级处理，对预激活值 Z 施加 LeakyReLU 激活函数，输出 H = LeakyReLU(Z)。

## 层次关系
```
leaky_relu_parent（顶层，2路并行）
  ├── leaky_relu_child col_1（第1列）
  └── leaky_relu_child col_2（第2列）
```

## leaky_relu_child 内部结构
```
lr_data_in ──→ [fxp_mul × leak_factor] ──→ mul_out
                                              ↓
lr_data_in ──→ [MUX: data_in >= 0 ?] ──→ [寄存器] ──→ lr_data_out
                  ↑ yes: pass through
                  ↑ no:  mul_out
```

## 数学定义
```
H = Z        (Z >= 0)
H = α × Z   (Z < 0)
```
- α = `lr_leak_factor_in`，Q8.8 定点格式，典型值 0.01

## 工作原理
- `fxp_mul` 始终计算 `data_in × leak_factor`（组合逻辑）
- 符号判断：`lr_data_in >= 0` 选择直通或乘法结果
- 输出寄存一拍，1 cycle 延迟
- 无效数据时输出清零

## leaky_relu_parent 角色
- 纯结构化封装，实例化 2 个 child
- 共享同一个 `lr_leak_factor_in`（所有列使用相同泄漏因子）

## 接口
| 信号 | 说明 |
|------|------|
| lr_data_in [15:0] | 预激活值 Z（来自 bias 模块） |
| lr_leak_factor_in [15:0] | 泄漏因子 α |
| lr_data_out [15:0] | 激活输出 H |
| lr_valid_out | 输出有效信号 |

## 简历话术
> 实现了 LeakyReLU 激活函数模块，正值直通、负值乘以泄漏因子 α，使用 Q8.8 定点乘法器，parent-child 层次化设计支持 2 路并行处理。
