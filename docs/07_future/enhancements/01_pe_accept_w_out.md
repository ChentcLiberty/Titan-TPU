# PE 权重加载机制改进方案

> **文档编号**: 13
> **创建日期**: 2026-01-22
> **状态**: 📋 设计阶段
> **优先级**: ⭐⭐⭐⭐ (高 - 面试加分项)
> **预计工作量**: 2-3天

---

## 📌 文档导航

- [问题背景](#问题背景)
- [当前方案分析](#当前方案分析)
- [改进方案设计](#改进方案设计)
- [方案对比](#方案对比)
- [实施计划](#实施计划)
- [验收标准](#验收标准)
- [面试价值](#面试价值)

---

## 🎯 改进目标

**核心问题**: tiny-tpu-v2 的权重加载机制使用 broadcast 控制，存在可扩展性和鲁棒性问题。

**改进目标**:
1. ✅ 提升权重加载机制的可扩展性
2. ✅ 增强系统的鲁棒性（自定时设计）
3. ✅ 符合工业级 systolic array 设计标准
4. ✅ 作为面试亮点展示设计改进能力

---

## 📊 问题背景

### 发现过程

在分析 PE 模块时，发现了一个设计问题：

```systemverilog
// 当前 PE 模块接口
module pe #(
    parameter DATA_WIDTH = 16
) (
    input  logic clk,
    input  logic rst,

    // 权重控制信号
    input  logic pe_accept_w_in,   // ✅ 有输入
    // ❌ 缺少 pe_accept_w_out      // ❌ 没有输出！

    input  logic signed [DATA_WIDTH-1:0] pe_weight_in,
    output logic signed [DATA_WIDTH-1:0] pe_weight_out,
    // ...
);
```

**关键观察**：
- PE 有 `pe_accept_w_in` 输入信号
- PE 有 `pe_weight_in/out` 用于权重数据传递
- **但是没有 `pe_accept_w_out` 输出信号**

**问题**：下一级 PE 如何知道何时接收权重？

### 当前实现方式

查看 `systolic.sv` 和测试代码后发现，tiny-tpu-v2 使用的是 **broadcast + multi-cycle hold** 策略：

```systemverilog
// systolic.sv 中的连接方式
assign pe_accept_w_in[i][j] = pe_accept_w_in_top;  // 广播给所有PE
```

```systemverilog
// 测试代码中的控制方式
pe_accept_w_in_top = 1'b1;
#(CLK_PERIOD * ARRAY_SIZE);  // 保持多个周期
pe_accept_w_in_top = 1'b0;
```

**工作原理**：
1. Control Unit 将 `pe_accept_w_in` 广播给所有 PE
2. 保持信号高电平 **ARRAY_SIZE 个周期**
3. 权重通过 `pe_weight_in/out` 从上到下逐级传递
4. 每个 PE 在信号为高时接收权重

---

## 🔍 当前方案分析

### 方案1：Broadcast + Multi-Cycle Hold（当前实现）

#### 时序图

```
Cycle:     0    1    2    3    4
           ┌────┬────┬────┬────┬────
accept_w   │ 1  │ 1  │ 1  │ 1  │ 0
           └────┴────┴────┴────┴────

PE[0][0]   │ W0 │    │    │    │
PE[1][0]   │    │ W0 │    │    │
PE[2][0]   │    │    │ W0 │    │
PE[3][0]   │    │    │    │ W0 │
```

#### 优点 ✅

1. **实现简单**
   - 只需一根控制线
   - 不需要修改 PE 模块接口
   - 代码量少

2. **对小规模阵列足够**
   - 2×2 阵列只需保持 2 个周期
   - 控制逻辑简单直观

3. **易于理解**
   - 学习曲线平缓
   - 适合教学和原型验证

#### 缺点 ❌

1. **时序脆弱性**
   ```systemverilog
   // 必须精确计算保持周期数
   #(CLK_PERIOD * ARRAY_SIZE);  // 如果算错，权重加载失败！
   ```
   - 依赖精确的时序控制
   - 容易出现 off-by-one 错误
   - 调试困难

2. **可扩展性差**
   ```systemverilog
   // 2×2 阵列
   #(CLK_PERIOD * 2);  // OK

   // 8×8 阵列
   #(CLK_PERIOD * 8);  // 需要修改控制代码！
   ```
   - 阵列大小改变时，必须修改控制逻辑
   - 不符合硬件设计的可配置性原则

3. **鲁棒性问题**
   - 如果某个 PE 的时钟有偏移（clock skew）
   - 如果权重传播路径有延迟
   - 可能导致权重加载失败

4. **面试扣分点**
   - 面试官会问："如果阵列是 16×16 怎么办？"
   - 面试官会问："如果不同 PE 的时钟有偏移怎么办？"
   - 无法给出令人满意的答案

---

## 🚀 改进方案设计

### 方案2：Cascaded Control（推荐方案）

#### 核心思想

**自定时设计（Self-Timed）**：每个 PE 在接收到权重后，自动通知下一级 PE。

#### 接口修改

```systemverilog
module pe #(
    parameter DATA_WIDTH = 16
) (
    input  logic clk,
    input  logic rst,

    // 权重控制信号（修改）
    input  logic pe_accept_w_in,    // ✅ 保留
    output logic pe_accept_w_out,   // ✨ 新增！

    input  logic signed [DATA_WIDTH-1:0] pe_weight_in,
    output logic signed [DATA_WIDTH-1:0] pe_weight_out,
    // ...
);
```

#### 内部逻辑

```systemverilog
// 在 PE 内部添加
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        pe_accept_w_out <= 1'b0;
    end else begin
        // 延迟一个周期传递控制信号
        pe_accept_w_out <= pe_accept_w_in;
    end
end
```

**关键点**：
- `pe_accept_w_out` 是 `pe_accept_w_in` 的延迟版本
- 延迟一个周期，正好对应权重数据的传播延迟
- 形成自然的流水线控制

#### 连接方式

```systemverilog
// systolic.sv 中的连接（修改后）
genvar i, j;
generate
    for (i = 0; i < ARRAY_SIZE; i++) begin : row
        for (j = 0; j < ARRAY_SIZE; j++) begin : col

            // 权重控制信号级联
            if (i == 0) begin
                // 第一行：连接到顶层输入
                assign pe_accept_w_in[i][j] = pe_accept_w_in_top;
            end else begin
                // 其他行：连接到上一行的输出
                assign pe_accept_w_in[i][j] = pe_accept_w_out[i-1][j];
            end

            // PE 实例化
            pe #(.DATA_WIDTH(DATA_WIDTH)) pe_inst (
                .clk(clk),
                .rst(rst),
                .pe_accept_w_in(pe_accept_w_in[i][j]),
                .pe_accept_w_out(pe_accept_w_out[i][j]),  // 新增
                // ...
            );
        end
    end
endgenerate
```

#### 时序图

```
Cycle:     0    1    2    3    4
           ┌────┬────┬────┬────┬────
accept_w   │ 1  │ 0  │ 0  │ 0  │ 0    ← 只需1个周期！
(top)      └────┴────┴────┴────┴────

PE[0][0]   │ W0 │    │    │    │
accept_out │ 0  │ 1  │ 0  │ 0  │

PE[1][0]   │    │ W0 │    │    │
accept_out │ 0  │ 0  │ 1  │ 0  │

PE[2][0]   │    │    │ W0 │    │
accept_out │ 0  │ 0  │ 0  │ 1  │

PE[3][0]   │    │    │    │ W0 │
```

**观察**：
- Control Unit 只需发送 **1 个周期** 的脉冲
- 控制信号自动在阵列中传播
- 完全自定时，不需要计算周期数

#### 优点 ✅

1. **自定时设计**
   - 不需要计算保持周期数
   - 控制信号自动传播
   - 鲁棒性强

2. **完全可扩展**
   ```systemverilog
   // 2×2 阵列
   pe_accept_w_in_top = 1'b1;
   @(posedge clk);
   pe_accept_w_in_top = 1'b0;

   // 8×8 阵列 - 控制代码完全相同！
   pe_accept_w_in_top = 1'b1;
   @(posedge clk);
   pe_accept_w_in_top = 1'b0;
   ```
   - 阵列大小改变，控制逻辑不变
   - 符合硬件可配置性原则

3. **工业标准**
   - 这是 systolic array 的标准做法
   - Google TPU、NVIDIA Tensor Core 都采用类似机制
   - 展示对工业级设计的理解

4. **面试加分项**
   - 可以对比两种方案，展示设计权衡
   - 体现对时序设计的深刻理解
   - 展示改进和优化能力

#### 缺点 ❌

1. **需要修改 PE 模块**
   - 增加一个输出端口
   - 增加一个寄存器
   - 但改动量很小（约10行代码）

2. **布线资源增加**
   - 每个 PE 多一根输出线
   - 但对于现代工艺，可以忽略不计

---

## 📊 方案对比

### 对比表格

| 维度 | 方案1: Broadcast | 方案2: Cascaded | 推荐 |
|------|------------------|-----------------|------|
| **实现复杂度** | ⭐⭐⭐⭐⭐ 简单 | ⭐⭐⭐⭐ 较简单 | 方案1 |
| **可扩展性** | ⭐⭐ 差 | ⭐⭐⭐⭐⭐ 优秀 | 方案2 |
| **鲁棒性** | ⭐⭐ 脆弱 | ⭐⭐⭐⭐⭐ 强 | 方案2 |
| **控制周期数** | ARRAY_SIZE | 1 | 方案2 |
| **代码改动量** | 0 | ~10行 | 方案1 |
| **工业标准** | ❌ 非标准 | ✅ 标准做法 | 方案2 |
| **面试价值** | ⭐⭐ 低 | ⭐⭐⭐⭐⭐ 高 | 方案2 |

### 关键指标对比

#### 1. 控制复杂度

**方案1**:
```systemverilog
// 需要计算周期数
pe_accept_w_in_top = 1'b1;
#(CLK_PERIOD * ARRAY_SIZE);  // 依赖阵列大小
pe_accept_w_in_top = 1'b0;
```

**方案2**:
```systemverilog
// 固定1个周期
pe_accept_w_in_top = 1'b1;
@(posedge clk);
pe_accept_w_in_top = 1'b0;
```

**结论**: 方案2 控制更简单，不依赖阵列大小。

#### 2. 可扩展性

**方案1**:
- 2×2 → 8×8: 需要修改控制代码
- 需要重新计算周期数
- 需要重新验证时序

**方案2**:
- 2×2 → 8×8: 控制代码完全不变
- 自动适应阵列大小
- 无需重新验证控制逻辑

**结论**: 方案2 完全可扩展。

#### 3. 时序鲁棒性

**方案1 的风险**:
```
如果 PE[2][0] 的时钟比 PE[0][0] 慢 0.5 个周期：
- PE[0][0] 在 T0 接收权重
- PE[1][0] 在 T1 接收权重
- PE[2][0] 在 T2.5 接收权重 ← 可能错过控制信号！
```

**方案2 的优势**:
```
每个 PE 的 accept_w_out 直接驱动下一级：
- 即使有 clock skew，控制信号也会正确传播
- 自定时设计天然抵抗时序偏差
```

**结论**: 方案2 更鲁棒。

### 最终推荐

**🎯 推荐方案2（Cascaded Control）**

**理由**:
1. **技术优势**: 可扩展、鲁棒、符合工业标准
2. **面试价值**: 展示设计改进能力和工业级思维
3. **项目定位**: 符合"魔改"目标，是优秀的改进点
4. **成本可控**: 改动量小（~10行代码），风险低

---

## 📋 实施计划

### Phase 1: 设计验证（1天）

#### 任务清单
- [ ] 详细阅读 `pe.sv` 源码
- [ ] 详细阅读 `systolic.sv` 源码
- [ ] 绘制当前权重加载时序图
- [ ] 设计新的 `pe_accept_w_out` 逻辑
- [ ] 绘制改进后的时序图
- [ ] 评估改动范围和风险

#### 输出文档
- 设计文档（本文档）
- 时序图（Visio/Draw.io）
- 风险评估报告

### Phase 2: 代码实现（1天）

#### 修改文件列表

**1. `rtl/pe.sv`**
```systemverilog
// 添加输出端口
module pe #(
    parameter DATA_WIDTH = 16
) (
    // ... 现有端口 ...
    output logic pe_accept_w_out,  // 新增
    // ...
);

// 添加控制逻辑
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        pe_accept_w_out <= 1'b0;
    end else begin
        pe_accept_w_out <= pe_accept_w_in;
    end
end
```

**2. `rtl/systolic.sv`**
```systemverilog
// 修改连接逻辑
genvar i, j;
generate
    for (i = 0; i < ARRAY_SIZE; i++) begin : row
        for (j = 0; j < ARRAY_SIZE; j++) begin : col
            if (i == 0) begin
                assign pe_accept_w_in[i][j] = pe_accept_w_in_top;
            end else begin
                assign pe_accept_w_in[i][j] = pe_accept_w_out[i-1][j];
            end

            pe #(.DATA_WIDTH(DATA_WIDTH)) pe_inst (
                .pe_accept_w_in(pe_accept_w_in[i][j]),
                .pe_accept_w_out(pe_accept_w_out[i][j]),  // 新增
                // ...
            );
        end
    end
endgenerate
```

**3. `tb/tb_systolic.sv`**
```systemverilog
// 简化控制逻辑
task load_weights();
    pe_accept_w_in_top = 1'b1;
    @(posedge clk);  // 只需1个周期！
    pe_accept_w_in_top = 1'b0;

    // 等待权重传播完成
    repeat(ARRAY_SIZE) @(posedge clk);
endtask
```

#### 预计改动量
- `pe.sv`: +5行
- `systolic.sv`: +3行
- `tb_systolic.sv`: -2行（简化）
- **总计**: +6行代码

### Phase 3: 测试验证（0.5天）

#### 测试用例

**1. 基础功能测试**
```systemverilog
// 测试权重加载是否正确
test_weight_loading();
- 加载权重到所有PE
- 检查每个PE的weight_reg是否正确
- 验证权重传播时序
```

**2. 时序验证**
```systemverilog
// 验证控制信号传播
test_accept_w_propagation();
- 检查pe_accept_w_out的时序
- 验证级联延迟是否正确
- 确认无竞争条件
```

**3. 可扩展性测试**
```systemverilog
// 测试不同阵列大小
test_scalability();
- 2×2 阵列
- 4×4 阵列
- 8×8 阵列（如果资源允许）
```

**4. 回归测试**
```systemverilog
// 确保不影响现有功能
test_regression();
- 运行所有现有测试用例
- 确保100%通过
```

#### 验证工具
- VCS 仿真
- Verdi 波形分析
- 覆盖率报告（确保 > 95%）

### Phase 4: 文档更新（0.5天）

#### 更新文档列表
- [ ] 更新 `CLAUDE.md`（项目总览）
- [ ] 更新 `03_TECHNICAL_REFERENCE.md`（技术参考）
- [ ] 更新 `09_INTERVIEW_PREP.md`（面试准备）
- [ ] 创建改进总结报告

---

## ✅ 验收标准

### 功能验收

| 验收项 | 标准 | 验证方法 |
|--------|------|----------|
| **权重加载正确性** | 所有PE权重正确 | 读取weight_reg，对比期望值 |
| **控制信号传播** | pe_accept_w_out时序正确 | Verdi波形分析 |
| **可扩展性** | 2×2/4×4/8×8都能工作 | 修改ARRAY_SIZE参数测试 |
| **回归测试** | 所有现有测试通过 | make regression |
| **覆盖率** | > 95% | VCS覆盖率报告 |

### 代码质量

- [ ] 代码符合 SystemVerilog 编码规范
- [ ] 所有信号命名清晰
- [ ] 添加详细注释
- [ ] 通过 lint 检查（如果有）

### 文档完整性

- [ ] 设计文档完整
- [ ] 时序图清晰
- [ ] 测试报告详细
- [ ] 面试问答准备好

---

## 🎤 面试价值

### 简历描述

**推荐写法**:
> "优化 Systolic Array 权重加载机制，采用 **cascaded control** 替代 broadcast 控制，实现 **自定时设计（self-timed）**，提升系统可扩展性和鲁棒性。该改进使控制逻辑与阵列大小解耦，符合工业级 TPU 设计标准。"

### 面试问答准备

#### Q1: 你在项目中做了哪些改进？

**回答框架**:
1. **发现问题**: "在分析 PE 模块时，我发现权重加载使用 broadcast 控制，存在可扩展性问题..."
2. **分析原因**: "当前方案需要保持控制信号 ARRAY_SIZE 个周期，阵列变大时必须修改控制代码..."
3. **提出方案**: "我设计了 cascaded control 方案，添加 pe_accept_w_out 端口，实现自定时传播..."
4. **展示结果**: "改进后，控制逻辑与阵列大小完全解耦，从 2×2 扩展到 8×8 无需修改任何控制代码..."

#### Q2: 为什么选择 cascaded control？

**回答要点**:
- **技术优势**: 自定时、可扩展、鲁棒
- **工业标准**: Google TPU、NVIDIA Tensor Core 都采用类似机制
- **权衡分析**: 虽然增加了一个端口，但带来的收益远大于成本

#### Q3: 如何验证改进的正确性？

**回答框架**:
1. **功能测试**: 权重加载正确性
2. **时序验证**: 波形分析，确认信号传播
3. **可扩展性测试**: 2×2/4×4/8×8 都能工作
4. **回归测试**: 确保不影响现有功能
5. **覆盖率**: > 95%

#### Q4: 这个改进的局限性是什么？

**诚实回答**:
- 需要修改 PE 模块接口（增加一个端口）
- 增加了少量布线资源
- 但这些成本相比收益是完全可接受的

**加分点**: 展示对设计权衡的理解

### 技术深度展示

**可以延伸讨论的话题**:
1. **Clock Domain Crossing**: 如果不同 PE 在不同时钟域怎么办？
2. **Metastability**: 如何处理亚稳态问题？
3. **Timing Closure**: 如何确保时序收敛？
4. **Power Optimization**: 是否可以结合 clock gating？

---

## 📝 总结

### 核心价值

1. **技术价值**: 提升系统可扩展性和鲁棒性
2. **学习价值**: 深入理解 systolic array 设计
3. **面试价值**: 展示设计改进能力和工业级思维
4. **项目价值**: 符合"魔改"定位，是优秀的改进点

### 下一步行动

1. **立即**: 将此改进添加到 Week 2 计划
2. **Phase 1 完成后**: 开始实施此改进
3. **实施完成后**: 更新简历和面试准备材料

### 参考资料

- Google TPU 论文: "In-Datacenter Performance Analysis of a TPU"
- Systolic Array 经典论文: "Why Systolic Architectures"
- NVIDIA Tensor Core 白皮书

---

*文档创建: 2026-01-22*
*最后更新: 2026-01-22*
*状态: 📋 设计阶段 → 待实施*
