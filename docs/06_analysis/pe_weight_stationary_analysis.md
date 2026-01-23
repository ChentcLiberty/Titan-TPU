# PE 模块 Weight Stationary 数据流分析

> **作者**: Claude Code
> **日期**: 2026-01-19
> **文件**: `_vendor/tiny-tpu/src/pe.sv`

---

## 1. Weight Stationary 核心概念

### 1.1 什么是 Weight Stationary？

**Weight Stationary（权重静止）** 是一种脉动阵列的数据流模式，其核心思想是：

- ✅ **权重（Weight）固定在 PE 中**，不需要每次计算都重新加载
- ✅ **输入数据（Input）从左向右流动**（West → East）
- ✅ **部分和（Partial Sum）从上向下流动**（North → South）

这种设计的优势：
1. **减少内存访问**：权重只加载一次，可以复用多次
2. **降低功耗**：避免频繁的权重读取
3. **提高吞吐量**：数据流水线化，每个周期都在计算

---

## 2. PE 模块架构分析

### 2.1 端口定义

```systemverilog
module pe (
    input logic clk, rst,

    // North 端口（来自上方 PE）
    input  logic signed [15:0] pe_psum_in,      // 部分和输入
    input  logic signed [15:0] pe_weight_in,    // 权重输入
    input  logic pe_accept_w_in,                // 权重接受信号

    // West 端口（来自左侧 PE）
    input  logic signed [15:0] pe_input_in,     // 数据输入
    input  logic pe_valid_in,                   // 数据有效信号
    input  logic pe_switch_in,                  // 切换信号
    input  logic pe_enabled,                    // PE 使能

    // South 端口（输出到下方 PE）
    output logic signed [15:0] pe_psum_out,     // 部分和输出
    output logic signed [15:0] pe_weight_out,   // 权重输出

    // East 端口（输出到右侧 PE）
    output logic signed [15:0] pe_input_out,    // 数据输出
    output logic pe_valid_out,                  // 数据有效输出
    output logic pe_switch_out                  // 切换信号输出
);
```

### 2.2 数据流方向

```
        North (权重 + 部分和)
            ↓
West (数据) → [PE] → East (数据)
            ↓
        South (权重 + 部分和)
```

---

## 3. Weight Stationary 实现机制

### 3.1 双缓冲权重寄存器

PE 模块使用 **双缓冲（Double Buffering）** 机制来实现权重的无缝切换：

```systemverilog
logic signed [15:0] weight_reg_active;    // 前台寄存器（正在使用）
logic signed [15:0] weight_reg_inactive;  // 后台寄存器（预加载）
```

**工作流程**：

1. **权重预加载阶段**：
   - 当 `pe_accept_w_in = 1` 时，新权重加载到 `weight_reg_inactive`
   - 此时 `weight_reg_active` 仍在使用旧权重进行计算
   - **关键**：不影响当前计算

2. **权重切换阶段**：
   - 当 `pe_switch_in = 1` 时，触发切换
   - `weight_reg_active = weight_reg_inactive`（组合逻辑，立即生效）
   - 新权重开始参与计算

3. **权重静止阶段**：
   - 权重保持在 `weight_reg_active` 中
   - 输入数据流过 PE，与固定权重进行 MAC 运算
   - **这就是 Weight Stationary 的核心**

### 3.2 代码实现

```systemverilog
// 组合逻辑：切换信号立即生效
always_comb begin
    if (pe_switch_in) begin
        weight_reg_active = weight_reg_inactive;  // 立即切换
    end
end

// 时序逻辑：权重加载
always_ff @(posedge clk or posedge rst) begin
    if (rst || !pe_enabled) begin
        weight_reg_active <= 16'b0;
        weight_reg_inactive <= 16'b0;
    end else begin
        if (pe_accept_w_in) begin
            weight_reg_inactive <= pe_weight_in;  // 预加载到后台
            pe_weight_out <= pe_weight_in;        // 传递给下方 PE
        end
    end
end
```

---

## 4. MAC 运算流程

### 4.1 MAC = Multiply-Accumulate

PE 的核心功能是执行 MAC 运算：

```
output = (input × weight) + partial_sum
```

### 4.2 数据通路

```
pe_input_in ──┐
              ├──> [fxp_mul] ──> mult_out ──┐
weight_reg_active ┘                         │
                                            ├──> [fxp_add] ──> mac_out ──> pe_psum_out
pe_psum_in ─────────────────────────────────┘
```

### 4.3 代码实现

```systemverilog
logic signed [15:0] mult_out;
wire signed [15:0] mac_out;

// 步骤1：乘法（定点数乘法）
fxp_mul mult (
    .ina(pe_input_in),           // 输入数据
    .inb(weight_reg_active),     // 固定权重
    .out(mult_out),              // 乘法结果
    .overflow()
);

// 步骤2：加法（累加部分和）
fxp_add adder (
    .ina(mult_out),              // 乘法结果
    .inb(pe_psum_in),            // 来自上方的部分和
    .out(mac_out),               // 最终结果
    .overflow()
);

// 步骤3：输出
always_ff @(posedge clk) begin
    if (pe_valid_in) begin
        pe_psum_out <= mac_out;  // 输出到下方 PE
    end
end
```

---

## 5. Q8.8 定点数格式

### 5.1 格式定义

**Q8.8** 表示：
- **8 位整数部分**（包含符号位）
- **8 位小数部分**
- 总共 **16 位**

```
[15:8] = 整数部分（有符号）
[7:0]  = 小数部分
```

### 5.2 数值范围

- **最大值**：`0x7FFF` = 127.99609375
- **最小值**：`0x8000` = -128.0
- **精度**：1/256 = 0.00390625

### 5.3 示例

| 十六进制 | 二进制 | 十进制 |
|---------|--------|--------|
| `0x0100` | `0000_0001.0000_0000` | 1.0 |
| `0x0180` | `0000_0001.1000_0000` | 1.5 |
| `0xFF00` | `1111_1111.0000_0000` | -1.0 |
| `0x0001` | `0000_0000.0000_0001` | 0.00390625 |

---

## 6. 在 Systolic Array 中的应用

### 6.1 2×2 阵列连接

```
        W11      W12
         ↓        ↓
D11 → [PE11] → [PE12]
         ↓        ↓
D21 → [PE21] → [PE22]
         ↓        ↓
       Out21    Out22
```

### 6.2 数据流动

1. **权重加载**（垂直方向）：
   - `W11` → PE11 → PE21
   - `W12` → PE12 → PE22
   - 权重在每个 PE 中保持静止

2. **输入数据流动**（水平方向）：
   - `D11` → PE11 → PE12
   - `D21` → PE21 → PE22
   - 数据每个周期向右移动一格

3. **部分和累加**（垂直方向）：
   - PE11 的输出 → PE21 的 `pe_psum_in`
   - PE12 的输出 → PE22 的 `pe_psum_in`
   - 部分和向下累加

### 6.3 矩阵乘法示例

计算 `C = A × B`：

```
A = [a11 a12]    B = [b11 b12]
    [a21 a22]        [b21 b22]
```

**时间步 T0**：加载权重
- PE11: W = b11
- PE12: W = b12
- PE21: W = b21
- PE22: W = b22

**时间步 T1**：
- PE11: `a11 × b11` → 部分和
- PE12: `a11 × b12` → 部分和

**时间步 T2**：
- PE21: `a21 × b11 + (a11 × b11)` → `c11`
- PE22: `a21 × b12 + (a11 × b12)` → `c12`

---

## 7. 关键时序

### 7.1 权重加载时序

```
Cycle 0: pe_accept_w_in = 1, pe_weight_in = W1
         → weight_reg_inactive = W1

Cycle 1: pe_switch_in = 1
         → weight_reg_active = W1 (组合逻辑，立即生效)

Cycle 2+: 权重保持在 weight_reg_active
          输入数据流过，进行 MAC 运算
```

### 7.2 数据流时序

```
Cycle N:   pe_valid_in = 1, pe_input_in = D1
           → MAC 运算: D1 × W + psum_in

Cycle N+1: pe_psum_out = MAC 结果
           pe_input_out = D1 (传递给右侧 PE)
```

---

## 8. 当前 Bug 分析

### 8.1 Bug 描述

**错误信息**：
```
Error-[ICPD] Illegal combination of drivers
Variable "weight_reg_active" 被多个 always 块驱动
```

### 8.2 问题根源

在 `pe.sv:52-58` 和 `pe.sv:58-87` 中：

```systemverilog
// always_comb 块（组合逻辑）
always_comb begin
    if (pe_switch_in) begin
        weight_reg_active = weight_reg_inactive;  // 驱动1
    end
end

// always_ff 块（时序逻辑）
always_ff @(posedge clk or posedge rst) begin
    if (rst || !pe_enabled) begin
        weight_reg_active <= 16'b0;  // 驱动2
    end
end
```

**问题**：`weight_reg_active` 同时被组合逻辑和时序逻辑驱动，违反了 SystemVerilog 规则。

### 8.3 修复方案

**方案1**：将 `always_comb` 改为 `always_ff`，在时钟边沿切换
**方案2**：使用 `assign` 语句实现组合逻辑
**方案3**：重新设计逻辑，避免多驱动

---

## 9. 面试问答准备

### Q1: 什么是 Weight Stationary 数据流？

**答**：Weight Stationary 是一种脉动阵列的数据流模式，权重固定在 PE 中不动，输入数据从左向右流动，部分和从上向下累加。这样可以减少内存访问，降低功耗，提高吞吐量。

### Q2: 为什么需要双缓冲权重寄存器？

**答**：双缓冲允许在不中断当前计算的情况下预加载新权重。后台寄存器加载新权重，前台寄存器继续使用旧权重计算，切换信号来时立即切换，实现无缝过渡。

### Q3: PE 的 MAC 运算流程是什么？

**答**：MAC = Multiply-Accumulate。首先用定点数乘法器计算 `input × weight`，然后用加法器将结果与来自上方的部分和相加，最终输出到下方 PE。公式是 `output = (input × weight) + partial_sum`。

### Q4: Q8.8 定点数格式的优势是什么？

**答**：Q8.8 用 16 位表示定点数，8 位整数 + 8 位小数。相比浮点数，定点数硬件实现简单、功耗低、面积小，适合神经网络推理。精度为 1/256，对大多数 AI 应用足够。

### Q5: 在 Systolic Array 中，数据如何流动？

**答**：权重垂直加载并保持静止，输入数据水平流动（左→右），部分和垂直累加（上→下）。每个 PE 执行 MAC 运算，将结果传递给下方 PE，实现矩阵乘法的流水线计算。

---

## 10. 总结

### 核心要点

1. ✅ **Weight Stationary**：权重固定，数据流动
2. ✅ **双缓冲机制**：无缝切换权重
3. ✅ **MAC 运算**：乘法 + 累加
4. ✅ **Q8.8 定点数**：8 位整数 + 8 位小数
5. ✅ **脉动阵列**：数据流水线化

### 下一步

- [ ] 修复 `weight_reg_active` 多驱动 Bug
- [ ] 运行 PE 模块测试
- [ ] 理解 Systolic Array 完整数据流
- [ ] 学习 VPU 和 Control Unit

---

*文档创建时间: 2026-01-19*
