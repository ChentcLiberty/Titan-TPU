# 定点数运算库 (fixedpoint.sv)

## 模块定位
Q8.8 定点数运算基础库，为整个 TPU 提供算术运算原语，被 PE、Bias、ReLU、Loss、Gradient Descent 等所有计算模块调用。

## 模块清单

### 核心运算模块（项目中实际使用）

| 模块 | 功能 | 类型 | 项目中调用位置 |
|------|------|------|----------------|
| `fxp_zoom` | 定点数位宽转换 | 组合 | 被所有运算模块内部调用 |
| `fxp_add` | 定点加法 | 组合 | bias_child (Z=WX+b) |
| `fxp_addsub` | 定点加减法 | 组合 | loss_child (H-Y), gradient_descent (θ-lr×g) |
| `fxp_mul` | 定点乘法 | 组合 | pe (MAC), leaky_relu (α×Z), loss (diff×2/N), gradient_descent (lr×g) |

### 扩展模块（库中提供，项目未直接使用）

| 模块 | 功能 | 说明 |
|------|------|------|
| `fxp_mul_pipe` | 流水线乘法 | 2级流水，适合高频设计 |
| `fxp_div` | 定点除法 | 组合逻辑，关键路径长 |
| `fxp_div_pipe` | 流水线除法 | WOI+WOF+3 级流水 |
| `fxp_sqrt` | 定点开方 | 组合逻辑 |
| `fxp_sqrt_pipe` | 流水线开方 | [WII/2]+WIF+2 级流水 |
| `fxp2float` | 定点→IEEE754 浮点 | 组合逻辑 |
| `fxp2float_pipe` | 流水线定点→浮点 | WII+WIF+2 级流水 |
| `float2fxp` | IEEE754 浮点→定点 | 组合逻辑 |
| `float2fxp_pipe` | 流水线浮点→定点 | WOI+WOF+4 级流水 |

## fxp_zoom（位宽转换，核心基础模块）
- 输入：WII.WIF 格式 → 输出：WOI.WOF 格式
- 支持 ROUND 参数控制舍入
- 溢出检测：正溢出饱和到最大正值，负溢出饱和到最小负值
- 被所有运算模块内部调用做中间结果位宽对齐

## fxp_mul（项目中最常用）
```
res = $signed(ina) × $signed(inb)   // 全精度乘法
out = fxp_zoom(res)                  // 截断回 Q8.8
```
- 中间结果位宽：(WIIA+WIIB).(WIFA+WIFB) = Q16.16
- 通过 fxp_zoom 截断回 Q8.8，带溢出检测

## fxp_add / fxp_addsub
- 先通过 fxp_zoom 对齐两个操作数位宽
- 扩展 1 bit 防止加法溢出
- addsub 通过取补码实现减法：`inbv = sub ? (~inbe)+1 : inbe`

## Q8.8 格式说明
- 总位宽：16-bit signed
- 整数部分：8-bit（含符号位），范围 -128 ~ +127
- 小数部分：8-bit，精度 1/256 ≈ 0.0039
- 转换：`fxp_value = real_value × 256`

## 简历话术
> 项目使用 Q8.8 定点运算库，包含加法、减法、乘法等原语，所有模块通过 fxp_zoom 实现位宽对齐和溢出饱和保护。PE 的 MAC、Bias 加法、ReLU 缩放、Loss 梯度计算均基于此库实现。
