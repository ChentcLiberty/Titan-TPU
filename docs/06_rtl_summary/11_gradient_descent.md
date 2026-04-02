# 梯度下降模块 (gradient_descent.sv)

## 模块定位
参数更新单元，嵌入在 Unified Buffer 内部，执行 SGD 权重/偏置更新：`θ_new = θ_old - lr × gradient`。

## 内部结构
```
grad_in ──→ [fxp_mul × lr_in] ──→ mul_out ──→ [fxp_addsub (sub)] ──→ sub_value_out ──→ [寄存器] ──→ value_updated_out
                                                    ↑
                                              sub_in_a (组合选择)
```

## 数学定义
```
value_new = value_old - learning_rate × gradient
```

## 偏置 vs 权重更新的区别
通过 `grad_bias_or_weight` 控制 `sub_in_a` 的来源：

| 模式 | grad_bias_or_weight | sub_in_a 来源 | 说明 |
|------|---------------------|---------------|------|
| 偏置更新 | 0 | 首次用 `value_old_in`，之后用 `value_updated_out` | 累积式：同一个偏置被多个梯度连续更新 |
| 权重更新 | 1 | 始终用 `value_old_in` | 逐元素：每个权重独立更新一次 |

## 两级组合 + 寄存输出
1. `fxp_mul`：`lr × gradient`（组合逻辑）
2. `fxp_addsub`：`sub_in_a - mul_out`（组合逻辑，sub=1 固定减法）
3. `always_ff`：寄存 `sub_value_out` → `value_updated_out`，1 cycle 延迟

## 控制信号
- `grad_descent_valid_in`：由 UB 的 `always_comb` 根据计数器状态自动生成
- `grad_descent_done_out`：延迟一拍的 valid，通知 UB 写回更新值

## 修复的 Bug
- `sub_in_a` 原先在 `always_comb` 和 `always_ff` 中都被赋值，导致多驱动
- 修复：`sub_in_a` 纯组合逻辑（`always_comb`），`value_updated_out` 纯时序逻辑（`always_ff`）

## 简历话术
> 实现了 SGD 梯度下降模块，支持偏置累积更新和权重逐元素更新两种模式。修复了 sub_in_a 多驱动 Bug，严格分离组合/时序逻辑。
