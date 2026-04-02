# Systolic Array 深度分析

## 1. 数据流详解

### 1.1 权重流 (Weight Flow) - 垂直传播

```
sys_weight_in_11 → PE11.pe_weight_in
                   PE11.pe_weight_out → PE21.pe_weight_in

sys_weight_in_12 → PE12.pe_weight_in
                   PE12.pe_weight_out → PE22.pe_weight_in
```

**关键点**：
- 权重从**上方**加载，沿**列**向下传播
- 每列有独立的 `sys_accept_w_*` 信号控制权重接受
- 权重通过双缓存机制（shadow/active）实现无缝切换

### 1.2 激活流 (Activation Flow) - 水平传播

```
sys_data_in_11 → PE11.pe_input_in
                 PE11.pe_input_out → PE12.pe_input_in

sys_data_in_21 → PE21.pe_input_in
                 PE21.pe_input_out → PE22.pe_input_in
```

**关键点**：
- 激活值从**左侧**流入，沿**行**向右传播
- 每个 PE 将输入延迟一拍后传递给右侧 PE
- 最右侧 PE 的输出被丢弃（未连接）

### 1.3 部分和流 (Partial Sum Flow) - 垂直累加

```
PE11: psum_in = 0 (第一行)
      psum_out = W11 × A11 + 0 → PE21.psum_in

PE21: psum_in = PE11.psum_out
      psum_out = W21 × A21 + psum_in → sys_data_out_21

PE12: psum_in = 0 (第一行)
      psum_out = W12 × A12 + 0 → PE22.psum_in

PE22: psum_in = PE12.psum_out
      psum_out = W22 × A22 + psum_in → sys_data_out_22
```

**关键点**：
- 第一行 PE 的 psum_in 固定为 0
- 部分和沿**列**向下累加
- 最底行 PE 的输出即为最终结果

### 1.4 控制信号流

#### Switch 信号 (对角线传播)
```
sys_switch_in → PE11.pe_switch_in
                PE11.pe_switch_out → PE12.pe_switch_in
                                     PE21.pe_switch_in
                PE12.pe_switch_out → PE22.pe_switch_in
```

**传播路径**：左上 → 右上 + 左下 → 右下（对角线扩散）

#### Valid 信号 (行列传播)
```
sys_start → PE11.pe_valid_in
            PE11.pe_valid_out → PE12.pe_valid_in (行传播)
                                PE21.pe_valid_in (列传播)
            PE12.pe_valid_out → PE22.pe_valid_in
            PE21.pe_valid_out → sys_valid_out_21
            PE22.pe_valid_out → sys_valid_out_22
```

**关键点**：
- PE11 的 valid 信号同时传播到 PE12（右）和 PE21（下）
- 这确保了数据在阵列中的同步流动

## 2. PE 使能控制机制

### 2.1 动态列使能

```systemverilog
always@(posedge clk or posedge rst) begin
    if(rst) begin
        pe_enabled <= '0;
    end else begin
        if(ub_rd_col_size_valid_in) begin
            pe_enabled <= (1 << ub_rd_col_size_in) - 1;
        end
    end
end
```

**功能**：根据 `ub_rd_col_size_in` 动态使能列

**示例**：
- `ub_rd_col_size_in = 0` → `pe_enabled = 2'b00` (无列使能)
- `ub_rd_col_size_in = 1` → `pe_enabled = 2'b01` (第0列使能)
- `ub_rd_col_size_in = 2` → `pe_enabled = 2'b11` (两列都使能)

**PE 映射**：
- `pe_enabled[0]` → PE11, PE21 (第0列)
- `pe_enabled[1]` → PE12, PE22 (第1列)

## 3. 矩阵乘法映射

### 3.1 计算示例：C = A × B

假设：
```
A = [a11  a12]    B = [b11  b12]    C = [c11  c12]
    [a21  a22]        [b21  b22]        [c21  c22]
```

### 3.2 权重预加载阶段

```
Cycle 0-3: 加载权重到 shadow register
  PE11 ← b11
  PE12 ← b12
  PE21 ← b21
  PE22 ← b22

Cycle 4: 切换权重 (sys_switch_in = 1)
  所有 PE 将 shadow → active
```

### 3.3 计算阶段

| Cycle | PE11 | PE12 | PE21 | PE22 | 说明 |
|-------|------|------|------|------|------|
| 5 | b11×a11 | - | - | - | a11 进入 PE11 |
| 6 | b11×a12 | b12×a11 | b21×a11 | - | a12→PE11, a11→PE12/PE21 |
| 7 | - | b12×a12 | b21×a12 | b22×a11 | 数据继续流动 |
| 8 | - | - | - | b22×a12 | 最后一次计算 |

### 3.4 输出结果

```
sys_data_out_21 = PE21.psum_out
                = b21×a21 + (b11×a11)
                = c21

sys_data_out_22 = PE22.psum_out
                = b22×a22 + (b12×a12)
                = c22
```

**注意**：这个 2×2 阵列每次只能计算部分结果，需要多次迭代完成完整矩阵乘法。

## 4. 时序分析

### 4.1 关键时序参数

- **权重加载延迟**：1 cycle (写入 shadow register)
- **权重切换延迟**：1 cycle (shadow → active)
- **MAC 计算延迟**：1 cycle (乘法 + 加法 + 寄存器)
- **数据传播延迟**：1 cycle/PE

### 4.2 流水线深度

对于 2×2 阵列：
- 水平方向：2 级流水线
- 垂直方向：2 级流水线
- 总延迟：约 3-4 cycles（从输入到输出）

## 5. 设计亮点

### 5.1 Weight Stationary 架构
- **优点**：权重固定在 PE 中，减少权重读取带宽
- **适用场景**：卷积神经网络（权重复用率高）

### 5.2 双缓存机制
- **shadow register**：后台加载新权重
- **active register**：前台执行计算
- **无缝切换**：通过 `pe_switch_in` 信号一次性切换

### 5.3 动态列使能
- 支持可变矩阵尺寸
- 节省功耗（未使用的列可以禁用）

## 6. 潜在问题与改进

### 6.1 当前问题

1. **输出丢弃**：PE12 和 PE22 的 `pe_input_out` 未连接
2. **权重传播**：PE21 和 PE22 的 `pe_weight_out` 未连接
3. **Switch 传播**：PE21 的 `pe_switch_out` 未连接

**影响**：这些信号在 2×2 阵列中确实不需要，但如果扩展到更大阵列会有问题。

### 6.2 扩展到 8×8 的挑战

1. **信号扇出**：valid 信号需要同时传播到多个 PE
2. **时序收敛**：更长的传播路径可能导致时序违例
3. **功耗**：64 个 PE 同时工作功耗较大

### 6.3 建议改进

1. **添加流水线寄存器**：在长路径上插入寄存器
2. **实现 Sparse 优化**：跳过零值计算
3. **添加 ECC 保护**：提高数据可靠性

## 7. 验证要点

### 7.1 功能验证

- [ ] 权重加载和切换
- [ ] 单个 PE 的 MAC 计算
- [ ] 部分和累加
- [ ] 数据流传播
- [ ] 列使能控制

### 7.2 边界条件

- [ ] 全零输入
- [ ] 全零权重
- [ ] 单列使能
- [ ] 双列使能
- [ ] 复位行为

### 7.3 性能验证

- [ ] 吞吐率测试
- [ ] 延迟测试
- [ ] 功耗测试（仿真）

---

**分析完成时间**：2026-01-24
**分析者**：Claude Sonnet 4.5
