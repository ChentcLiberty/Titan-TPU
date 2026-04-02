# IC 面试核心技术要点速查卡

> 基于 TitanTPU 项目，3月1日前必须内化的核心知识点

---

## 1. 项目30秒电梯演讲（背熟）

"我做了一个 AI 加速器项目，基于 GitHub 开源 TPU（1000+ stars）深度定制。实现了 2×2 Weight Stationary 脉动阵列，支持前向推理和反向训练。用 SystemVerilog 写 RTL，VCS 仿真验证，所有核心模块测试通过。修过多驱动、竞争条件等 Bug。规划加 ECC 容错、稀疏优化和 AXI 接口。"

---

## 2. 架构核心（必问）

### Weight Stationary 数据流
- **权重固定**：权重预加载到 PE，不移动
- **输入水平流**：激活数据从左向右传播
- **部分和垂直流**：累加结果从上向下传播
- **优势**：权重复用率高，适合推理（权重矩阵大）

### 2×2 Systolic Array 连接
```
        W11    W12
        ↓      ↓
I11 → PE11 → PE12
      ↓      ↓
I21 → PE21 → PE22
      ↓      ↓
    OUT21   OUT22
```

### PE 双缓冲机制
- `weight_reg_active`：前台计算
- `weight_reg_inactive`：后台加载
- `pe_switch_in` 信号切换：计算与加载并行

### Unified Buffer 7种读取模式
0. Input（左侧输入）
1. Weight（顶部权重）
2. Bias（偏置标量）
3. Y（真实标签）
4. H（激活输出）
5. Grad_Bias（偏置梯度）
6. Grad_Weight（权重梯度）

### VPU 数据通路（4-bit控制）
- `1100`：前向（Bias → LeakyReLU）
- `1111`：过渡（前向 + Loss + 缓存H）
- `0001`：反向（LeakyReLU导数）

---

## 3. 定点数运算（Q8.8格式）

- **格式**：8位整数 + 8位小数 = 16位
- **范围**：-128.0 ~ 127.996
- **精度**：1/256 ≈ 0.0039
- **转换**：`real_to_fxp(x) = x * 256`
- **溢出检测**：fxp_mul/fxp_addsub 都有 overflow 输出

---

## 4. 验证方法学（重点）

### SystemVerilog 特性
- **Clocking Block**：消除竞争条件，`#1step` 时序
- **SVA 断言**：`assert property (@(posedge clk) rst |-> (out == 0))`
- **Constrained Random**：`rand logic [15:0] data; constraint c {data inside {[-512:512]};}`

### 覆盖率（5维）
- **Line**：代码行覆盖
- **Condition**：条件分支覆盖
- **FSM**：状态机覆盖
- **Toggle**：信号翻转覆盖
- **Branch**：分支覆盖

### 测试策略
- **Directed Test**：已知输入输出，验证基本功能
- **Random Test**：随机输入，覆盖边界情况
- **Self-Checking**：testbench 自动比对期望值

---

## 5. Bug 定位与修复（必问）

### Bug 1: PE 多驱动
- **现象**：`weight_reg_active` 被 `always_comb` 和 `always_ff` 同时驱动
- **原因**：组合逻辑和时序逻辑混用
- **修复**：统一到 `always_ff`，纯时序逻辑
- **教训**：一个信号只能有一个驱动源

### Bug 2: Unified Buffer 竞争条件
- **现象**：读取命令初始化时多驱动
- **原因**：`always_comb` 中初始化需要寄存的信号
- **修复**：迁移到 `always_ff`
- **教训**：初始化逻辑要分清组合/时序

### Bug 3: Gradient Descent 多驱动
- **现象**：`sub_in_a` 在两个 always 块中赋值
- **原因**：组合选择逻辑和时序更新混淆
- **修复**：`sub_in_a` 纯组合，`value_updated_out` 纯时序
- **教训**：组合逻辑用 `always_comb`，时序逻辑用 `always_ff`

---

## 6. EDA 工具链

### VCS 编译选项
```bash
vcs -full64 -sverilog -timescale=1ns/1ps \
    -debug_access+all -kdb \
    -cm line+cond+fsm+tgl+branch
```

### Verdi 波形调试
- **FSDB 格式**：`$fsdbDumpfile()` + `$fsdbDumpvars()`
- **信号搜索**：按模块层次、信号名、值变化
- **波形对比**：多窗口对比不同信号

### DC 综合（规划中）
- **目标频率**：200MHz
- **工艺库**：TSMC 28nm（假设）
- **约束**：时序约束、面积约束、功耗约束

---

## 7. 规划中的增强特性

### ECC SECDED (Hamming 39,32)
- **编码**：32位数据 + 6位校验 + 1位全局奇偶 = 39位
- **SEC**：单比特纠错（syndrome 定位错误位）
- **DED**：双比特检错（syndrome≠0 且 parity_ok）
- **开销**：面积 +15%，延迟 +1 cycle
- **应用**：车规 ASIL-B，海思/海光方向

### Sparse PE 优化
- **零值跳过**：检测 `weight==0 || input==0`，跳过 MAC
- **Clock Gating**：ICG 单元，`gated_clk = clk & enable_latch`
- **功耗降低**：30-40%（稀疏度 50%）
- **应用**：NVIDIA/AMD 方向

### AXI4-Lite 接口
- **握手机制**：VALID/READY 双向握手
- **通道**：读地址、读数据、写地址、写数据、写响应
- **规则**：VALID 先于 READY，VALID 不可撤销
- **应用**：SoC 集成，所有公司通用

---

## 8. 高频面试问题速答

### Q: 为什么选 Weight Stationary？
**A**: 推理场景权重矩阵远大于激活，权重固定复用率高。Google TPU v1 也用这个，工业验证。训练场景 Output Stationary 更优。

### Q: 如何处理大于阵列的矩阵？
**A**: Tiling 分块。100×100 矩阵用 8×8 阵列，分成 13×13 个块，循环计算。双缓冲优化：计算当前块时预加载下一块。

### Q: 利用率为什么不是 100%？
**A**: 三个原因：1) 矩阵边界 padding（100×100 → 104×104，损失 7.5%）；2) Pipeline bubble（启动和排空阶段）；3) Sparse 跳过（功耗优化的 trade-off）。

### Q: 如何验证 ECC 正确性？
**A**: 故障注入测试。遍历所有 39 个单比特位置（应该纠正），遍历所有 C(39,2)=741 个双比特组合（应该检测）。覆盖率 100%。

### Q: 遇到最难的 Bug？
**A**: PE 多驱动问题。VCS 报 `Illegal combination of drivers`，定位到 `weight_reg_active` 被两个 always 块驱动。修复方法是统一到 `always_ff`。学到：一个信号只能一个驱动源，组合/时序要分清。

### Q: 为什么不用 GPU？
**A**: TPU 优势：1) 能效比高（专用 GEMM，功耗 <100W vs GPU 350W）；2) 成本低（边缘部署）；3) 延迟可控（推理场景）。GPU 优势：通用性、CUDA 生态。

---

## 9. 反问面试官（准备3个）

1. "贵司的 NPU/TPU 采用什么数据流架构？Weight Stationary 还是其他？"
2. "验证团队使用什么方法学？UVM 还是传统 testbench？"
3. "新人的培养路径是怎样的？会有 mentor 带吗？"

---

## 10. 针对不同公司的侧重点

| 公司 | 强调点 | 准备问题 |
|------|--------|----------|
| **海思/海光** | ECC SECDED、高可靠性、Bug定位 | "SECDED 延迟多少？如何处理不可纠正错误？" |
| **NVIDIA/AMD** | Sparse 优化、Clock Gating、功耗 | "和 Ampere 2:4 稀疏化有什么区别？" |
| **中兴微/飞腾** | AXI 接口、SoC 集成、验证覆盖率 | "如何做 SoC 级验证？" |
| **芯原/AI方向** | Systolic Array、PE 设计、架构 | "如何支持不同神经网络算子？" |

---

**最后提醒**：
- 每个技术点都要能**脱口而出**，不能卡壳
- 画图能力：能在白板上画出 Systolic Array、PE 内部结构、数据流
- 数字敏感：Q8.8 范围、覆盖率百分比、性能提升倍数，张口就来
- 自信但不傲慢：承认不足（ECC/Sparse 还没实现），但展示学习能力
