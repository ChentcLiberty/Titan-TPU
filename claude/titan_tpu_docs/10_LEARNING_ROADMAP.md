# 10 - 学习路线图

> 从入门到进阶的完整学习路径，包含资源链接和时间估算

---

## 📋 目录

1. [学习阶段总览](#1-学习阶段总览)
2. [阶段一：基础入门](#2-阶段一基础入门)
3. [阶段二：项目实战](#3-阶段二项目实战)
4. [阶段三：深入研究](#4-阶段三深入研究)
5. [阶段四：全栈扩展](#5-阶段四全栈扩展)
6. [资源汇总](#6-资源汇总)
7. [推荐书籍](#7-推荐书籍)

---

## 1. 学习阶段总览

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         AI 加速器学习路线图                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   阶段一 (4周)          阶段二 (8周)         阶段三 (8周)        阶段四 (持续)    │
│   ─────────────      ─────────────      ─────────────      ─────────────  │
│                                                                             │
│   ┌───────────┐      ┌───────────┐      ┌───────────┐      ┌───────────┐  │
│   │  基础入门  │ ───▶ │  项目实战  │ ───▶ │  深入研究  │ ───▶ │  全栈扩展  │  │
│   │           │      │           │      │           │      │           │  │
│   │ • SV 语法 │      │ • tiny-tpu │      │ • Gemmini │      │ • TVM-VTA │  │
│   │ • 数字逻辑│      │ • ECC/Sparse│     │ • NVDLA   │      │ • 编译器  │  │
│   │ • 体系结构│      │ • AXI     │      │ • 论文    │      │ • FPGA    │  │
│   │ • AI 基础 │      │ • 验证    │      │ • 综合    │      │ • SoC     │  │
│   └───────────┘      └───────────┘      └───────────┘      └───────────┘  │
│         │                  │                  │                  │         │
│         ▼                  ▼                  ▼                  ▼         │
│    [能看懂代码]       [有项目经验]       [能发论文]        [成为专家]        │
│                                                                             │
│   ════════════════════════════════════════════════════════════════════════ │
│         │                  │                                               │
│         ▼                  ▼                                               │
│      实习就绪           秋招就绪                                            │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 阶段一：基础入门 (4周)

### 2.1 SystemVerilog 基础 (Week 1)

**学习目标**：
- 掌握 SV 基本语法
- 理解可综合代码规范
- 能读懂 RTL 代码

**学习内容**：

| 主题 | 学时 | 资源 |
|------|------|------|
| 数据类型 (logic, reg, wire) | 2h | SV LRM Chapter 6 |
| 运算符和表达式 | 2h | SV LRM Chapter 11 |
| always_comb, always_ff, always_latch | 4h | Sutherland SV Guide |
| 模块和端口 | 2h | 任意 SV 教程 |
| generate 语句 | 2h | SV LRM Chapter 27 |
| interface 和 modport | 2h | SV LRM Chapter 25 |

**练习项目**：
1. 实现一个 4-bit 加法器
2. 实现一个 8-bit 移位寄存器
3. 实现一个简单 FSM (红绿灯)

### 2.2 数字逻辑基础 (Week 2)

**学习目标**：
- 理解组合逻辑和时序逻辑
- 掌握基本电路单元
- 理解时序分析基础

**学习内容**：

| 主题 | 学时 | 资源 |
|------|------|------|
| 组合逻辑 (MUX, Decoder, Encoder) | 4h | 数字电子技术基础 |
| 时序逻辑 (FF, Latch, Counter) | 4h | 数字电子技术基础 |
| 有限状态机 (Mealy, Moore) | 4h | FSM 设计教程 |
| 时序约束 (Setup, Hold) | 4h | STA 基础教程 |
| 流水线基础 | 2h | CAAQA Chapter 3 |

### 2.3 计算机体系结构 (Week 3)

**学习目标**：
- 理解存储层次
- 理解流水线
- 理解并行计算

**学习内容**：

| 主题 | 学时 | 资源 |
|------|------|------|
| 存储层次 (Cache, Memory) | 4h | CAAQA Chapter 2 |
| 流水线 (Hazards, Forwarding) | 4h | CAAQA Chapter 3 |
| 并行计算 (SIMD, SIMT) | 4h | CAAQA Chapter 4 |
| 数据流架构 | 2h | Dataflow 论文 |
| 脉动阵列 | 4h | Systolic Array 教程 |

### 2.4 AI 算法基础 (Week 4)

**学习目标**：
- 理解神经网络基础
- 理解 CNN/Transformer 计算
- 理解 GEMM 优化

**学习内容**：

| 主题 | 学时 | 资源 |
|------|------|------|
| 神经网络基础 (前向/反向) | 4h | Deep Learning Book |
| CNN 卷积计算 | 4h | CS231n |
| Transformer Attention | 4h | Attention is All You Need |
| GEMM 优化 | 4h | 各种 GEMM 优化博客 |
| 量化和稀疏 | 4h | 量化论文 |

---

## 3. 阶段二：项目实战 (8周)

### 3.1 tiny-tpu-v2 实战 (Week 5-8)

**学习目标**：
- 完成 Titan-TPU V2 项目
- 理解脉动阵列实现
- 掌握 RTL 验证流程

**参考**: 详见 [04_WORKFLOW_DETAILED.md](./04_WORKFLOW_DETAILED.md)

### 3.2 验证方法学 (Week 9-10)

**学习目标**：
- 掌握 SV 验证基础
- 理解 UVM 框架
- 达到 90% 覆盖率

**学习内容**：

| 主题 | 学时 | 资源 |
|------|------|------|
| SV Testbench 基础 | 8h | SV for Verification |
| 随机约束 | 4h | SV Randomization |
| 功能覆盖率 | 4h | SV Coverage |
| UVM 基础 | 8h | UVM Cookbook |
| UVM Agent/Env | 8h | UVM Tutorial |

### 3.3 综合与分析 (Week 11-12)

**学习目标**：
- 掌握 DC 综合流程
- 理解 PPA 分析
- 能优化设计

**学习内容**：

| 主题 | 学时 | 资源 |
|------|------|------|
| DC 综合脚本 | 4h | DC User Guide |
| 时序约束 SDC | 4h | SDC Tutorial |
| 时序分析 | 4h | PrimeTime 基础 |
| 面积优化 | 4h | DC Optimization |
| 功耗分析 | 4h | Power Analysis |

---

## 4. 阶段三：深入研究 (8周)

### 4.1 Gemmini 研究 (Week 13-16)

**学习目标**：
- 理解 Gemmini 架构
- 掌握 Chipyard 生态
- 能修改参数配置

**学习路径**：

```
Week 13: 阅读 Gemmini 论文
         └── "Gemmini: An Agile Systolic Array Generator" (DAC 2021)
         
Week 14: 搭建 Chipyard 环境
         └── 安装 Scala, SBT, Verilator
         └── Clone Chipyard
         
Week 15: 运行 Gemmini 仿真
         └── 跑通 MNIST 示例
         └── 理解配置参数
         
Week 16: 修改配置
         └── 改变阵列大小
         └── 改变数据流
         └── 分析性能变化
```

**资源**：
- GitHub: https://github.com/ucb-bar/gemmini
- Chipyard: https://github.com/ucb-bar/chipyard
- 论文: DAC 2021 Gemmini

### 4.2 NVDLA 学习 (Week 17-18)

**学习目标**：
- 理解工业级 NPU 架构
- 学习模块划分方法
- 学习验证方法论

**学习路径**：

```
Week 17: 架构学习
         └── 阅读 NVDLA Primer
         └── 理解 CMAC, SDP, PDP 模块
         
Week 18: 深入学习
         └── 阅读 CMAC 代码
         └── 理解验证方法
         └── 整理面试素材
```

**资源**：
- 网站: https://nvdla.org
- GitHub: https://github.com/nvdla/hw
- 文档: NVDLA Hardware Architecture

### 4.3 论文阅读 (Week 19-20)

**必读论文**：

| 论文 | 主题 | 重要性 |
|------|------|--------|
| Google TPU (ISCA 2017) | TPU v1 架构 | ⭐⭐⭐⭐⭐ |
| Eyeriss (ISCA 2016) | Row Stationary | ⭐⭐⭐⭐⭐ |
| SCNN (ISCA 2017) | 稀疏卷积 | ⭐⭐⭐⭐ |
| Gemmini (DAC 2021) | 生成器 | ⭐⭐⭐⭐ |
| Ampere Sparsity | 2:4 稀疏 | ⭐⭐⭐⭐ |

---

## 5. 阶段四：全栈扩展 (持续)

### 5.1 TVM-VTA 学习

**学习目标**：
- 理解编译器基础
- 打通软硬件栈
- 能部署模型

**学习路径**：

```
1. TVM 编译器基础 (2周)
   └── Relay IR
   └── Schedule
   └── Codegen
   
2. VTA 硬件架构 (2周)
   └── VTA 微架构
   └── ISA 设计
   
3. 端到端部署 (2周)
   └── 模型量化
   └── FPGA 部署
```

**资源**：
- TVM: https://tvm.apache.org
- VTA: https://github.com/apache/tvm-vta

### 5.2 FPGA 实战

**学习目标**：
- 在实际硬件上验证
- 理解 FPGA 约束
- 能做演示

**学习路径**：

```
1. 选择 FPGA 板卡
   └── Artix-7 (低成本): Basys3, Arty
   └── Zynq (带 ARM): PYNQ, ZCU104
   
2. Vivado 学习
   └── 创建项目
   └── 综合实现
   └── 调试 (ILA)
   
3. 移植项目
   └── 修改代码适配
   └── 添加约束
   └── 性能测试
```

### 5.3 SoC 集成

**学习目标**：
- 理解 SoC 架构
- 能与 CPU 协作
- 完整系统

**学习路径**：

```
1. RISC-V 基础
   └── 蜂鸟 E203
   └── Rocket Chip
   
2. 总线集成
   └── AXI Interconnect
   └── APB 外设
   
3. 软件驱动
   └── Bare-metal 驱动
   └── Linux 驱动
```

---

## 6. 资源汇总

### 6.1 在线课程

| 课程 | 平台 | 主题 |
|------|------|------|
| CS231n | Stanford | CNN |
| CS217 | Stanford | 硬件加速器 |
| MIT 6.004 | MIT OCW | 计算机体系结构 |
| Nand2Tetris | Coursera | 从零构建计算机 |

### 6.2 GitHub 项目

| 项目 | 星数 | 用途 |
|------|------|------|
| tiny-tpu-v2 | 1k+ | 入门实战 |
| Gemmini | 1k+ | 学术研究 |
| NVDLA | 2k+ | 工业参考 |
| Ztachip | 500+ | FPGA 实战 |
| TVM-VTA | 1k+ | 编译器全栈 |

### 6.3 论文合集

创建 NotebookLM 笔记本，上传以下论文：
1. TPU v1 (ISCA 2017)
2. Eyeriss (ISCA 2016)
3. SCNN (ISCA 2017)
4. Gemmini (DAC 2021)
5. AXI Protocol Spec

### 6.4 工具手册

| 工具 | 手册 |
|------|------|
| VCS | VCS User Guide |
| Verdi | Verdi User Guide |
| DC | Design Compiler User Guide |
| UVM | UVM Cookbook |

---

## 7. 推荐书籍

### 入门级

| 书名 | 作者 | 主题 |
|------|------|------|
| 数字电子技术基础 | 阎石 | 数字逻辑 |
| SystemVerilog for Design | Sutherland | SV 语法 |
| Writing Testbenches | Bergeron | 验证基础 |

### 进阶级

| 书名 | 作者 | 主题 |
|------|------|------|
| Computer Architecture: A Quantitative Approach | Hennessy & Patterson | 体系结构 |
| The UVM Primer | Salemi | UVM |
| Synthesis and Optimization of Digital Circuits | De Micheli | 综合 |

### 高级

| 书名 | 作者 | 主题 |
|------|------|------|
| Efficient Processing of Deep Neural Networks | Sze | DNN 加速 |
| Deep Learning | Goodfellow | 深度学习 |

---

*文档版本: v1.0 | 更新时间: 2025-01-16*
