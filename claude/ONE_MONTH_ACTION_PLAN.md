# Titan-TPU 一个月行动计划

> **目标**: 完成可展示的找实习项目
> **时间**: 4周（2026-01-19 ~ 2026-02-16）
> **核心**: 基于 tiny-tpu 魔改 + Git 记录学习过程

---

## 项目概览

### 源码统计
```
_vendor/tiny-tpu/src/
├── pe.sv                 (2.5KB)  ⭐ 核心 - MAC单元
├── systolic.sv           (4.2KB)  ⭐ 核心 - 脉动阵列
├── tpu.sv                (7.0KB)  ⭐ 核心 - 顶层
├── vpu.sv                (13KB)   向量处理单元
├── unified_buffer.sv     (24KB)   统一缓存
├── control_unit.sv       (2.0KB)  控制单元
├── fixedpoint.sv         (32KB)   定点运算库
└── 其他VPU子模块...
────────────────────────────────
总计: 16个文件, ~3000行代码
```

### 魔改目标（简历亮点）
| 特性 | 技术方案 | 面试价值 |
|------|----------|----------|
| **ECC 容错** | Hamming(39,32) SECDED | 车规芯片必问 |
| **Sparse 优化** | 零值跳过 + Clock Gating | 功耗优化必问 |
| **AXI 总线** | AXI4-Lite 接口 | SoC集成必问 |

---

## Week 1: 理解核心模块

### Day 1-2: 环境 + PE模块
**目标**: 跑通第一个测试

```bash
# 1. 初始化Git仓库
cd /home/jjt/TitanTPU
git init
git add .
git commit -m "init: 项目初始化，包含tiny-tpu源码"

# 2. 阅读PE模块
cat _vendor/tiny-tpu/src/pe.sv

# 3. 运行原项目测试（使用iverilog+cocotb）
cd _vendor/tiny-tpu
make test_pe
```

**学习重点**:
- [ ] 理解 Weight Stationary 数据流
- [ ] 理解 Q8.8 定点数格式（8位整数 + 8位小数）
- [ ] 理解 MAC 运算：`out = in_data * weight + partial_sum`

**Git提交**:
```bash
git commit -m "docs: 添加PE模块学习笔记"
```

### Day 3-4: Systolic Array
**目标**: 理解脉动阵列数据流

```bash
cat _vendor/tiny-tpu/src/systolic.sv
make test_systolic
```

**学习重点**:
- [ ] 2x2 阵列如何连接
- [ ] 数据如何在PE之间流动
- [ ] Weight 如何加载和保持

**Git提交**:
```bash
git commit -m "docs: 添加Systolic Array学习笔记"
```

### Day 5-7: VPU + Control Unit
**目标**: 理解完整数据通路

```bash
cat _vendor/tiny-tpu/src/vpu.sv
cat _vendor/tiny-tpu/src/control_unit.sv
make test_tpu
```

**学习重点**:
- [ ] VPU 的 bias/relu/loss 流水线
- [ ] 94-bit ISA 指令格式
- [ ] 完整前向传播流程

**Week 1 里程碑**:
- [ ] 能画出 TPU 数据流图
- [ ] 能解释每个模块的作用
- [ ] 所有原项目测试通过

---

## Week 2: ECC 魔改

### Day 8-9: ECC 原理学习
**目标**: 理解 Hamming SECDED

**学习资源**:
- Gemini/目录下的参考资料
- 搜索 "Hamming SECDED tutorial"

**学习重点**:
- [ ] Hamming(7,4) 基础原理
- [ ] SECDED = Single Error Correct, Double Error Detect
- [ ] Hamming(39,32) 的校验位计算

### Day 10-12: 实现 ECC 模块
**目标**: 创建 ecc_encoder.sv 和 ecc_decoder.sv

```bash
# 创建魔改目录
mkdir -p rtl/ecc
```

**文件结构**:
```
rtl/ecc/
├── ecc_encoder.sv    # 32bit数据 → 39bit编码
├── ecc_decoder.sv    # 39bit编码 → 32bit数据 + 错误标志
└── ecc_wrapper.sv    # 包装器，集成到PE
```

**核心代码框架** (ecc_encoder.sv):
```systemverilog
module ecc_encoder (
    input  logic [31:0] data_in,
    output logic [38:0] data_out  // 32 data + 7 parity
);
    // Hamming(39,32) 编码逻辑
    // P1 覆盖位置 1,3,5,7,9...
    // P2 覆盖位置 2,3,6,7,10...
    // ...
endmodule
```

**Git提交**:
```bash
git add rtl/ecc/
git commit -m "feat(ecc): 实现Hamming(39,32)编码解码模块"
```

### Day 13-14: ECC 测试
**目标**: 验证单bit纠错、双bit检错

```bash
mkdir -p tb
# 创建 tb/tb_ecc.sv
```

**测试用例**:
- [ ] 无错误：数据正确通过
- [ ] 单bit错误：自动纠正
- [ ] 双bit错误：检测到错误标志

**Git提交**:
```bash
git commit -m "test(ecc): 添加ECC模块测试，覆盖率100%"
```

**Week 2 里程碑**:
- [ ] ECC 编码/解码模块完成
- [ ] 测试通过
- [ ] 能解释 Hamming 码原理（面试准备）

---

## Week 3: Sparse 优化

### Day 15-16: Sparse 原理
**目标**: 理解稀疏优化策略

**学习重点**:
- [ ] 为什么神经网络有大量零值（ReLU激活后）
- [ ] 零值跳过如何节省功耗
- [ ] Clock Gating 原理

### Day 17-19: 实现 Sparse PE
**目标**: 修改 PE 模块支持零值跳过

```bash
mkdir -p rtl/sparse
```

**文件结构**:
```
rtl/sparse/
├── pe_sparse.sv      # 带零值检测的PE
├── zero_detector.sv  # 零值检测逻辑
└── clock_gate.sv     # Clock Gating单元
```

**核心逻辑**:
```systemverilog
module pe_sparse (
    input  logic clk,
    input  logic [15:0] data_in,
    input  logic [15:0] weight,
    // ...
);
    // 零值检测
    wire is_zero = (data_in == 16'h0) || (weight == 16'h0);

    // Clock Gating - 零值时关闭MAC时钟
    wire mac_clk;
    clock_gate cg (.clk(clk), .en(!is_zero), .gclk(mac_clk));

    // MAC运算只在非零时执行
    always_ff @(posedge mac_clk) begin
        // ...
    end
endmodule
```

**Git提交**:
```bash
git commit -m "feat(sparse): 实现零值跳过和Clock Gating"
```

### Day 20-21: Sparse 测试 + 功耗分析
**目标**: 量化功耗节省

**测试场景**:
- [ ] 50% 稀疏度：预期节省 ~40% 功耗
- [ ] 90% 稀疏度：预期节省 ~80% 功耗

**Git提交**:
```bash
git commit -m "test(sparse): 添加稀疏度测试，功耗降低40%"
```

**Week 3 里程碑**:
- [ ] Sparse PE 模块完成
- [ ] 功耗数据可量化
- [ ] 能解释 Clock Gating 原理（面试准备）

---

## Week 4: AXI 集成 + 收尾

### Day 22-23: AXI 协议学习
**目标**: 理解 AXI4-Lite 基础

**学习资源**:
- Gemini/IHI0022E_amba_axi_and_ace_protocol_spec.pdf
- _vendor/verilog-axi/rtl/ 参考代码

**学习重点**:
- [ ] AXI4-Lite 5通道：AW, W, B, AR, R
- [ ] 握手协议：VALID/READY
- [ ] 地址映射

### Day 24-26: 实现 AXI Wrapper
**目标**: 为 TPU 添加 AXI4-Lite 接口

```bash
mkdir -p rtl/axi
```

**文件结构**:
```
rtl/axi/
├── tpu_axi_wrapper.sv    # TPU的AXI包装器
└── axi_reg_bank.sv       # 寄存器组
```

**寄存器映射**:
| 地址 | 名称 | 功能 |
|------|------|------|
| 0x00 | CTRL | 控制寄存器 |
| 0x04 | STATUS | 状态寄存器 |
| 0x08 | DATA_IN | 数据输入 |
| 0x0C | DATA_OUT | 数据输出 |

**Git提交**:
```bash
git commit -m "feat(axi): 实现AXI4-Lite接口包装器"
```

### Day 27-28: 系统集成测试
**目标**: 完整系统测试

```bash
# 创建顶层测试
# tb/tb_titan_tpu.sv
```

**测试内容**:
- [ ] ECC + Sparse + AXI 联合工作
- [ ] 完整矩阵乘法测试
- [ ] 错误注入测试

**Git提交**:
```bash
git commit -m "test: 系统集成测试通过"
```

### Day 29-30: 文档 + 面试准备
**目标**: 完善文档，准备面试

**文档清单**:
- [ ] README.md - 项目介绍
- [ ] docs/architecture.md - 架构文档
- [ ] docs/interview_qa.md - 面试问答

**面试必备问题**:
1. 为什么选择 Weight Stationary？
2. ECC 如何实现单bit纠错？
3. Sparse 优化能节省多少功耗？
4. AXI 握手协议如何工作？

**Git提交**:
```bash
git commit -m "docs: 完善项目文档"
git tag v1.0 -m "一个月项目完成"
```

**Week 4 里程碑**:
- [ ] AXI 接口完成
- [ ] 系统集成测试通过
- [ ] 文档完善
- [ ] 面试问答准备好

---

## 最终目录结构

```
/home/jjt/TitanTPU/
├── _vendor/
│   ├── tiny-tpu/          # 原始代码（不修改）
│   └── verilog-axi/       # AXI参考库
├── rtl/                   # 魔改模块
│   ├── ecc/
│   │   ├── ecc_encoder.sv
│   │   ├── ecc_decoder.sv
│   │   └── ecc_wrapper.sv
│   ├── sparse/
│   │   ├── pe_sparse.sv
│   │   ├── zero_detector.sv
│   │   └── clock_gate.sv
│   └── axi/
│       ├── tpu_axi_wrapper.sv
│       └── axi_reg_bank.sv
├── tb/                    # 测试文件
│   ├── tb_ecc.sv
│   ├── tb_sparse.sv
│   └── tb_titan_tpu.sv
├── sim/                   # 仿真脚本
│   └── Makefile
├── docs/                  # 项目文档
│   ├── architecture.md
│   └── interview_qa.md
├── claude/                # AI辅助文档
└── README.md              # 项目说明
```

---

## Git 提交规范

```bash
# 格式: <type>(<scope>): <description>

# type:
#   feat     - 新功能
#   fix      - Bug修复
#   docs     - 文档
#   test     - 测试
#   refactor - 重构

# 示例:
git commit -m "feat(ecc): 实现Hamming编码器"
git commit -m "test(sparse): 添加50%稀疏度测试"
git commit -m "docs: 更新架构文档"
```

---

## 每日检查清单

```markdown
## 今日完成
- [ ] 代码/学习内容
- [ ] Git提交
- [ ] 笔记更新

## 遇到的问题
- 问题描述
- 解决方案

## 明日计划
- 任务1
- 任务2
```

---

## 简历一句话

> "基于开源 TPU 项目深度魔改，添加 **ECC 容错**（Hamming SECDED）、**稀疏化优化**（零值跳过 + Clock Gating，功耗降低 40%）、**AXI4-Lite 接口**，使用 SystemVerilog 实现，有完整测试和文档。"

---

## 快速命令

```bash
# 环境
cd /home/jjt/TitanTPU

# Git
git status
git add .
git commit -m "message"
git log --oneline

# 测试（使用原项目的iverilog+cocotb）
cd _vendor/tiny-tpu && make test_pe

# 查看源码
cat _vendor/tiny-tpu/src/pe.sv
```

---

*创建时间: 2026-01-19*
