# Unified Buffer 深度分析

> **作者**: Chen Weidong
> **日期**: 2026-01-31
> **模块**: Unified Buffer
> **文件**: `_vendor/tiny-tpu/src/unified_buffer.sv`

---

## 目录

1. [模块概述](#模块概述)
2. [从功能角度看 UB](#从功能角度看-ub)
3. [从数据流角度看 UB](#从数据流角度看-ub)
4. [从算法计算角度看 UB](#从算法计算角度看-ub)
5. [完整训练流程](#完整训练流程)
6. [关键设计技巧](#关键设计技巧)
7. [总结](#总结)

---

## 模块概述

### Unified Buffer 是什么？

Unified Buffer (UB) 是 TPU 的**核心数据枢纽**，承担三个关键角色：

```
┌─────────────────────────────────────────┐
│         Unified Buffer                  │
│                                         │
│  角色1: 数据仓库                        │
│    存储所有训练数据                     │
│                                         │
│  角色2: 数据调度器                      │
│    按脉动阵列时序要求输出数据           │
│                                         │
│  角色3: 参数更新器                      │
│    内置梯度下降模块，就地更新参数       │
└─────────────────────────────────────────┘
```

### 参数

```systemverilog
parameter int UNIFIED_BUFFER_WIDTH = 128  // 内存大小：128个16位数据
parameter int SYSTOLIC_ARRAY_WIDTH = 2    // 脉动阵列宽度：2×2
```

---

## 从功能角度看 UB

### 1. 数据存储

```systemverilog
logic [15:0] ub_memory [0:127];  // 128个16位存储单元
```

**存储的数据类型**：

```
参数数据：
  ├── 权重 (W)
  └── 偏置 (bias)

激活数据：
  ├── 输入 (X)
  └── 隐藏层输出 (H)

训练数据：
  ├── 标签 (Y)
  ├── 权重梯度 (dL/dW)
  └── 偏置梯度 (dL/dbias)
```

### 2. 数据读取

**7 种读取模式** (通过 `ub_ptr_select` 控制)：

| ptr_select | 数据类型 | 目标模块 | 用途 |
|------------|----------|----------|------|
| 0 | 输入数据 (X) | Systolic Array 左侧 | 前向/反向传播 |
| 1 | 权重 (W) | Systolic Array 顶部 | 前向传播 |
| 2 | 偏置 (bias) | VPU | 前向传播 |
| 3 | 标签 (Y) | VPU | 损失计算 |
| 4 | 激活值 (H) | VPU | 反向传播 |
| 5 | 旧偏置 | 梯度下降模块 | 参数更新 |
| 6 | 旧权重 | 梯度下降模块 | 参数更新 |

### 3. 数据写入

**2 种写入源**：

```systemverilog
// 从 VPU 写入（计算结果）
input logic [15:0] ub_wr_data_in [2]
input logic ub_wr_valid_in [2]

// 从 Host 写入（加载参数）
input logic [15:0] ub_wr_host_data_in [2]
input logic ub_wr_host_valid_in [2]
```

### 4. 梯度下降模块

**内置 2 个梯度下降模块**：

```systemverilog
generate
    for (i=0; i<2; i++) begin
        gradient_descent gradient_descent_inst (
            .lr_in(learning_rate_in),
            .grad_in(ub_wr_data_in[i]),         // 梯度
            .value_old_in(value_old_in[i]),     // 旧参数
            .value_updated_out(value_updated_out[i])  // 新参数
        );
    end
endgenerate
```

**功能**：
```
新参数 = 旧参数 - 学习率 × 梯度
```

---

## 从数据流角度看 UB

### 整体架构

```
┌─────────────────────────────────────────────────────────────┐
│                    Unified Buffer                           │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  Memory: [W, bias, X, H, Y, gradients, ...]         │   │
│  └──────────────────────────────────────────────────────┘   │
│         ↓ 读取          ↓ 读取        ↑ 写入                │
│      权重/输入         H/Y          计算结果                 │
│                                                             │
│  ┌─────────────┐  ┌─────────────┐                          │
│  │ grad_descent│  │ grad_descent│  ← 梯度下降模块          │
│  │    [0]      │  │    [1]      │                          │
│  └─────────────┘  └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
           ↓                ↓              ↑
    ┌──────────┐      ┌──────────┐        │
    │ Systolic │ →    │   VPU    │ ───────┘
    │  Array   │      │          │
    └──────────┘      └──────────┘
    矩阵乘法          激活/损失/梯度
```

### 前向传播数据流

```
Step 1: 读取输入和权重
  UB → 输入数据 X → Systolic Array (左侧)
  UB → 权重 W → Systolic Array (顶部)

Step 2: 矩阵乘法
  Systolic Array: Z = W × X

Step 3: 加偏置和激活
  UB → 偏置 bias → VPU
  Systolic Array → Z → VPU
  VPU: H = activation(Z + bias)

Step 4: 写回结果
  VPU → H → UB (存储，用于反向传播)
```

### 反向传播数据流

```
Step 1: 计算输出层梯度
  UB → 预测值 H → VPU
  UB → 标签 Y → VPU
  VPU: dL/dH = (H - Y) × activation'(H)

Step 2: 计算权重梯度（脉动阵列）
  UB → dL/dH → Systolic Array (左侧)
  UB → X^T → Systolic Array (顶部)
  Systolic Array: dL/dW = dL/dH × X^T
  Systolic Array → dL/dW → VPU → UB

Step 3: 计算偏置梯度（VPU直接算）
  VPU: dL/dbias = sum(dL/dH)
  VPU → dL/dbias → UB

Step 4: 更新参数
  UB 读取 bias_old → 梯度下降模块
  UB 读取 dL/dbias → 梯度下降模块
  梯度下降: bias_new = bias_old - lr × dL/dbias
  梯度下降 → bias_new → UB

  UB 读取 W_old → 梯度下降模块
  UB 读取 dL/dW → 梯度下降模块
  梯度下降: W_new = W_old - lr × dL/dW
  梯度下降 → W_new → UB
```

---

## 从算法计算角度看 UB

### 神经网络的数学公式

```
前向传播：
  Z = W × X + bias
  H = activation(Z)
  Loss = (H - Y)²

反向传播：
  dL/dH = 2(H - Y) × activation'(Z)
  dL/dW = dL/dH × X^T
  dL/dbias = sum(dL/dH)

参数更新：
  W_new = W_old - lr × dL/dW
  bias_new = bias_old - lr × dL/dbias
```

### 硬件如何实现这些公式

| 公式 | 硬件模块 | UB 的作用 |
|------|----------|-----------|
| Z = W × X | Systolic Array | 提供 W 和 X |
| H = activation(Z + bias) | VPU | 提供 bias，存储 H |
| Loss = (H - Y)² | VPU | 提供 H 和 Y |
| dL/dH = ... | VPU | 提供 H 和 Y |
| dL/dW = dL/dH × X^T | Systolic Array | 提供 dL/dH 和 X^T |
| dL/dbias = sum(dL/dH) | VPU | 接收 dL/dbias |
| W_new = W - lr × dL/dW | UB 内部梯度下降模块 | 提供 W_old 和 dL/dW |
| bias_new = bias - lr × dL/dbias | UB 内部梯度下降模块 | 提供 bias_old 和 dL/dbias |

---

## 完整训练流程

### 阶段1：前向传播

```
T0-T2: UB 读取输入 X，错开输出到脉动阵列
  T0: X[0] → Systolic[0]
  T1: X[0], X[1] → Systolic[0], Systolic[1]
  T2: X[1] → Systolic[1]

T0-T2: UB 读取权重 W，从底向上输出到脉动阵列
  T0: W[1,0] → Systolic[0]
  T1: W[0,0], W[1,1] → Systolic[0], Systolic[1]
  T2: W[0,1] → Systolic[1]

T3-T5: 脉动阵列计算 Z = W × X
  T3: Z[0,0] 输出
  T4: Z[1,0], Z[0,1] 输出
  T5: Z[1,1] 输出

T3-T5: UB 读取偏置，VPU 计算 H = activation(Z + bias)
  T3: bias[0] + Z[0,0] → H[0,0]
  T4: bias[0] + Z[1,0] → H[1,0]
       bias[1] + Z[0,1] → H[0,1]
  T5: bias[1] + Z[1,1] → H[1,1]

T6-T8: VPU 写回 H 到 UB
```

### 阶段2：计算损失

```
T9-T11: UB 读取 H 和 Y 到 VPU
  VPU 计算 Loss = (H - Y)²
```

### 阶段3：反向传播 - 计算梯度

```
T12-T14: VPU 计算 dL/dH = 2(H - Y) × activation'(H)

并行计算两种梯度：

路径A（慢）：计算权重梯度
  T15-T17: UB 读取 dL/dH 到脉动阵列
  T15-T17: UB 读取 X^T 到脉动阵列
  T18-T20: 脉动阵列计算 dL/dW = dL/dH × X^T
  T21-T23: VPU 接收 dL/dW，写回 UB

路径B（快）：计算偏置梯度
  T12-T14: VPU 直接累加 dL/dbias = sum(dL/dH)
  T15: VPU 写回 dL/dbias 到 UB
```

### 阶段4：更新参数

```
先更新偏置（因为梯度先算完）：
  T16: UB 发送 ptr_select=5，启动偏置更新
  T17-T18: UB 读取 bias_old
  T17-T18: UB 读取 dL/dbias（已经在 UB 中）
  T17-T18: 梯度下降模块计算 bias_new = bias_old - lr × dL/dbias
  T19-T20: 梯度下降模块写回 bias_new 到 UB

后更新权重（等梯度算完）：
  T24: UB 发送 ptr_select=6，启动权重更新
  T25-T27: UB 读取 W_old
  T25-T27: UB 读取 dL/dW（已经在 UB 中）
  T25-T27: 梯度下降模块计算 W_new = W_old - lr × dL/dW
  T28-T30: 梯度下降模块写回 W_new 到 UB
```

---

## 关键设计技巧

### 1. 错开读取（Staggered Reading）

**为什么错开？**
```
脉动阵列的数据流是波浪式的
不同 PE 在不同时刻需要数据
```

**如何错开？**
```systemverilog
if(rd_input_time_counter >= i &&
   rd_input_time_counter < rd_input_row_size + i &&
   i < rd_input_col_size) begin
    ub_rd_input_data_out[i] <= ub_memory[rd_input_ptr];
    rd_input_ptr = rd_input_ptr + 1;
end
```

**时间计数器控制**：
```
T0: counter=0, 只有 i=0 满足 (0>=0)
T1: counter=1, i=0 和 i=1 都满足 (1>=0, 1>=1)
T2: counter=2, 只有 i=1 满足 (2>=1)
```

### 2. 递减/递增循环

**矩阵数据（Input, Y, H, Weight）：递减循环**
```systemverilog
for (int i = SYSTOLIC_ARRAY_WIDTH-1; i >= 0; i--) begin
    ub_rd_input_data_out[i] <= ub_memory[rd_input_ptr];
    rd_input_ptr = rd_input_ptr + 1;  // 阻塞赋值
end
```

**原因**：
```
递减循环确保高索引通道先读取
配合阻塞赋值实现单周期多次读取

i=1 先执行 → 读 memory[ptr]，ptr++
i=0 后执行 → 读 memory[ptr]（更新后的）
```

**向量数据（Bias）：递增循环**
```systemverilog
for (int i = 0; i < SYSTOLIC_ARRAY_WIDTH; i++) begin
    ub_rd_bias_data_out[i] <= ub_memory[rd_bias_ptr + i];  // 并行读取
end
```

**原因**：
```
偏置是向量，连续存储
可以用 ptr+i 并行访问
不需要递减
```

### 3. 权重的斜对角读取

**权重需要从底向上读取**：
```
权重矩阵：[w00 w01]
         [w10 w11]

加载顺序：
  T0: w10 (底层)
  T1: w00, w11
  T2: w01 (顶层)
```

**实现**：
```systemverilog
// 初始化指针到底层
rd_weight_ptr = ub_rd_addr_in + ub_rd_row_size*ub_rd_col_size - ub_rd_col_size;

// skip_size = 斜对角移动距离
rd_weight_skip_size = ub_rd_col_size + 1;

// 循环内跳跃读取
for (int i = SYSTOLIC_ARRAY_WIDTH-1; i >= 0; i--) begin
    ub_rd_weight_data_out[i] <= ub_memory[rd_weight_ptr];
    rd_weight_ptr = rd_weight_ptr - rd_weight_skip_size;
end

// 循环后修正指针
rd_weight_ptr = rd_weight_ptr + rd_weight_skip_size + 1;
```

### 4. 梯度下降模块集成

**为什么集成在 UB 内部？**
```
1. 减少数据搬运
   旧参数不需要离开 UB

2. 简化控制逻辑
   参数更新在 UB 内部完成

3. 提高更新速度
   避免数据在模块间传输的延迟
```

---

## 总结

### UB 的三个核心角色

```
1. 数据仓库
   存储所有训练需要的数据
   128 个 16 位存储单元

2. 数据调度器
   按照脉动阵列的时序要求
   错开输出数据

3. 参数更新器
   内置梯度下降模块
   就地更新参数
```

### 训练流程的本质

```
前向传播：数据从 UB 流向脉动阵列和 VPU
反向传播：梯度从 VPU 和脉动阵列流回 UB
参数更新：UB 内部完成，不需要外部干预

UB 是整个 TPU 的核心枢纽！
```

### 关键设计模式

| 数据类型 | 循环方向 | 指针操作 | 原因 |
|----------|----------|----------|------|
| 输入 (Input) | 递减 | ptr++ | 匹配脉动阵列时序 |
| 权重 (Weight) | 递减 | ptr -= skip | 斜对角读取 |
| 偏置 (Bias) | 递增 | ptr + i | 并行读取 |
| Y 矩阵 | 递减 | ptr++ | 匹配脉动阵列输出 |
| H 矩阵 | 递减 | ptr++ | 匹配脉动阵列输出 |

---

*文档创建: 2026-01-31*
*作者: Chen Weidong*
*基于: Tiny TPU 项目*
