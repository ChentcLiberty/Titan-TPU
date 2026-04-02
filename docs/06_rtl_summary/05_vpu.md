# 向量处理单元 (vpu.sv)

## 模块定位
Systolic Array 的后处理单元，通过 4-bit 控制字动态配置数据通路，支持前向推理、过渡、反向传播三种模式。

## 数据通路架构
```
Systolic Output → [Bias] → [LeakyReLU] → [Loss] → [LeakyReLU'] → Output
                  bit[3]    bit[2]        bit[1]    bit[0]
```

## 4-bit 控制字 (vpu_data_pathway)
| 编码 | 模式 | 激活模块 | 数据流 |
|------|------|----------|--------|
| 0000 | 空闲 | 无 | 无输出 |
| 1100 | 前向 | Bias + LeakyReLU | sys → bias → relu → out |
| 1111 | 过渡 | 全部 | sys → bias → relu → loss → relu' → out |
| 0001 | 反向 | LeakyReLU' | sys → relu' → out |

## 子模块实例化（每个2路并行）
1. **bias_parent**：偏置加法，Z = WX + b
2. **leaky_relu_parent**：LeakyReLU 激活，H = max(αZ, Z)
3. **loss_parent**：MSE 损失梯度，dL/dH = (2/N)(H - Y)
4. **leaky_relu_derivative_parent**：激活导数，dL/dZ = dL/dH × relu'(Z)

## 旁路机制
每个模块未激活时，输入直接旁路到下一级中间信号：
```
if (pathway[3]) → 连接 bias
else            → 旁路，vpu_input 直接送 b_to_lr 中间线
```

## H 矩阵缓存
- 过渡模式（1111）时：LeakyReLU 输出缓存到 `last_H_data` 寄存器
- 后续反向传播使用缓存的 H，而非从 UB 重新读取
- 非过渡模式：H 从 UB 的 H 端口读取

## 设计特点
- 纯组合逻辑路由（`always @(*)`），仅 H 缓存使用时序逻辑
- 2 路并行处理，匹配 2×2 Systolic Array 的输出宽度

## 简历话术
> 设计了 VPU 向量处理单元，通过 4-bit 控制字动态配置 Bias/ReLU/Loss/ReLU' 四级流水通路，支持前向推理和反向训练模式切换。实现了 H 矩阵缓存机制减少 UB 读取次数。
