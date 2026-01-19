# Titan-TPU V2 项目总览

> **最后更新**: 2026-01-18
> **当前阶段**: Phase 1 - 核心理解 (Week 1)
> **项目状态**: 🔄 进行中 - PE模块调试

---

## 📌 快速导航

- [项目定位](#项目定位)
- [当前进度](#当前进度)
- [技术栈](#技术栈)
- [目录结构](#目录结构)
- [AI工具策略](#ai工具策略)
- [下一步计划](#下一步计划)
- [关键资源](#关键资源)

---

## 🎯 项目定位

### 核心目标
基于开源 tiny-tpu-v2 项目进行深度魔改，打造一个**高可靠、低功耗的 AI 加速器**，用于：
- ✅ **成都实习**（2025年春季）
- ✅ **上海秋招**（2025年秋季）

### 三大魔改特性
| 特性 | 技术方案 | 目标公司 | 面试价值 |
|------|----------|----------|----------|
| **ECC 容错** | Hamming(39,32) SECDED | 海思、海光、车规芯片 | ⭐⭐⭐⭐⭐ |
| **Sparse 优化** | 零值跳过 + Clock Gating | NVIDIA、AMD、寒武纪 | ⭐⭐⭐⭐⭐ |
| **AXI 总线** | AXI4-Lite 工业级接口 | 所有 SoC 公司 | ⭐⭐⭐⭐ |

### 项目分层路线
```
第1层（当前）: tiny-tpu-v2 魔改 → 成都实习
第2层: AXI 接口升级 (TAXI/pulp-axi) → 工业级质量
第3层: 深入研究 (Gemmini/NVDLA/Ztachip) → 上海秋招
第4层: 编译器全栈 (TVM-VTA) → 系统架构师
```

---

## 📊 当前进度

### 总体进度
```
Phase 1 - 核心理解        [██░░░░░░░░] 20%
  ├─ 环境搭建              ✅ 完成
  ├─ PE 模块理解           🔄 进行中（调试Bug）
  ├─ Systolic Array       ⬜ 待做
  ├─ VPU                  ⬜ 待做
  └─ Control Unit         ⬜ 待做

Phase 2 - 魔改特性        [░░░░░░░░░░] 0%
Phase 3 - 系统集成        [░░░░░░░░░░] 0%
Phase 4 - 验证环境        [░░░░░░░░░░] 0%
Phase 5 - 综合分析        [░░░░░░░░░░] 0%
Phase 6 - 面试准备        [░░░░░░░░░░] 0%
```

### 已完成 ✅
- [x] 项目目录结构创建
- [x] 环境配置脚本 (env_setup.sh)
- [x] VCS Makefile 创建
- [x] 下载 tiny-tpu-v2 源码
- [x] 下载 verilog-axi 库
- [x] 创建 tb_pe.sv 测试文件
- [x] 完整文档系统建立（12份文档）

### 进行中 🔄
- [ ] **修复 PE 模块 Bug**
  - 问题：`weight_reg_active` 被 always_comb 和 always_ff 同时驱动
  - 文件：`_vendor/tiny-tpu-v2/src/pe.sv` 第 52-58 行
  - 状态：待修复

### 待办事项 ⬜
- [ ] PE 模块测试通过
- [ ] Systolic Array 理解与测试
- [ ] VPU 模块理解
- [ ] Control Unit 理解
- [ ] Golden Model (Python) 创建

### 当前 Bug 详情
```
Error-[ICPD] Illegal combination of drivers
Variable "weight_reg_active" 被多个 always 块驱动
位置: _vendor/tiny-tpu-v2/src/pe.sv:52-58
原因: always_comb 和 always_ff 同时驱动同一信号
```

---

## 🛠️ 技术栈

### 硬件环境
- **主机**: Windows + VMware Workstation
- **虚拟机**: CentOS 7
- **内存**: 16GB+

### EDA 工具
```bash
VCS:    /home/jjt/install/synopsys/vcs/vcs/T-2022.06
Verdi:  /home/jjt/install/synopsys/verdi/verdi/T-2022.06
DC:     /home/jjt/install/synopsys/dc/syn/T-2022.03-SP2
```

### 编程语言
- **RTL**: SystemVerilog (主要)
- **验证**: SystemVerilog + UVM
- **建模**: Python (Golden Model)
- **脚本**: Bash, Makefile, Tcl

### 核心技术
- **架构**: Weight Stationary Systolic Array
- **数据格式**: Q8.8 定点数
- **指令集**: 94-bit ISA
- **阵列规模**: 2×2 (可扩展到 8×8)

---

## 📁 目录结构

```
/home/jjt/TitanTPU/
│
├── claude/                              # 📚 项目文档系统
│   ├── 00_README.md                     # 导航指南
│   ├── 01_MASTER_INSTRUCTIONS.md        # ⭐ 核心Instructions
│   ├── 05_CLAUDE_CODE_SETUP.md          # 环境配置
│   ├── 11_SESSION_TEMPLATES.md          # 对话模板
│   └── titan_tpu_docs/                  # 完整12份文档
│       ├── 02_PROJECT_OVERVIEW.md       # 项目总览
│       ├── 03_TECHNICAL_REFERENCE.md    # 技术参考
│       ├── 04_WORKFLOW_DETAILED.md      # 12周详细计划
│       ├── 06_AI_TOOLS_GUIDE.md         # AI工具使用指南
│       ├── 07_PROGRESS_TRACKER.md       # 进度追踪
│       ├── 08_DEBUG_LOG.md              # Debug日志
│       ├── 09_INTERVIEW_PREP.md         # 面试准备
│       ├── 10_LEARNING_ROADMAP.md       # 学习路线
│       └── 12_SCRIPTS_COLLECTION.md     # 脚本集合
│
├── Gemini/                              # 📖 参考资料库
│   ├── Titan-TPU V2 架构与设计原理全解(The Bible).pdf
│   ├── Titan-TPU V2 指令架构ISA参考手册.pdf
│   ├── Titan-TPU V2 数据格式与量化标准.pdf
│   ├── Titan-TPU V2 硬件接口规范.pdf
│   ├── Titan-TPU V2 核心知识速通指南.pdf
│   ├── TPU v1/v2/v3/v4 论文集
│   ├── NVIDIA A100 白皮书
│   ├── Computer Architecture 第六版
│   ├── AMBA AXI 协议规范
│   └── 开源项目合集用于后续优化.txt
│
└── CLAUDE.md                            # 📌 本文件（项目总览）
```

### 实际项目目录（待创建/进行中）
```
/home/jjt/Titan_TPU_V2/                  # 主项目目录
├── _vendor/                             # 第三方库
│   ├── tiny-tpu-v2/                     # ✅ 核心TPU代码
│   └── verilog-axi/                     # ✅ AXI库
├── rtl/                                 # 📋 魔改模块
│   ├── ecc/                             # ECC模块
│   ├── sparse/                          # Sparse优化
│   └── axi/                             # AXI包装器
├── tb/                                  # Testbench
├── sim/vcs/                             # VCS仿真
├── uvm/                                 # UVM验证环境
├── syn/                                 # DC综合
├── model/                               # Golden Model
└── doc/                                 # 项目文档
```

---

## 🤖 AI工具策略

### 工具分工矩阵

| 工具 | 主要用途 | 使用场景 | 优先级 |
|------|----------|----------|--------|
| **Claude Opus 4.5 网页版** | 架构设计、复杂问题、项目规划 | 需要深度思考的任务 | ⭐⭐⭐⭐⭐ |
| **Claude Code CLI** | VCS调试、快速修复、代码审查 | Linux终端快速解决问题 | ⭐⭐⭐⭐⭐ |
| **Gemini Pro** | 长代码审查、多文件分析 | 需要大上下文（100万token） | ⭐⭐⭐⭐ |
| **NotebookLM** | 学习论文、理解原理 | 上传PDF文档提问 | ⭐⭐⭐⭐ |
| **ChatGPT** | 简单语法问题、快速查询 | 基础问题 | ⭐⭐⭐ |

### 问题分流决策树

```
遇到问题？
│
├─ VCS编译错误？
│  ├─ 简单错误（语法、拼写） → Claude Code CLI
│  └─ 复杂错误（时序、架构） → Claude Opus 网页版
│
├─ 需要理解代码？
│  ├─ 单个文件 → Claude Code CLI
│  └─ 多个文件/系统级 → Gemini Pro
│
├─ 需要学习原理？
│  ├─ 有论文/文档 → NotebookLM
│  └─ 没有文档 → Claude Opus
│
├─ 需要设计模块？
│  ├─ 简单模块 → Claude Code CLI
│  └─ 复杂模块/系统 → Claude Opus
│
├─ 需要代码审查？
│  ├─ 短代码（<100行） → Claude Code CLI
│  └─ 长代码（>100行） → Gemini Pro
│
└─ 简单语法问题？ → ChatGPT
```

### 会话管理策略

**解决"换对话框记不住历史"的问题**：

1. **Master Instructions 方法**
   - 把 `claude/01_MASTER_INSTRUCTIONS.md` 粘贴到 Claude Project Instructions
   - 每次新对话自动加载项目背景

2. **Session Templates 方法**
   - 使用 `claude/11_SESSION_TEMPLATES.md` 中的模板
   - 新对话启动模板
   - 会话交接模板

3. **Progress Tracker 方法**
   - 更新 `claude/titan_tpu_docs/07_PROGRESS_TRACKER.md`
   - 新对话时粘贴当前进度

4. **Git 版本控制**
   - 所有代码提交到 Git
   - 新AI可以查看 Git 历史

---

## 📅 下一步计划

### 立即任务（本周）
1. **修复 PE 模块 Bug**
   - 分析 `weight_reg_active` 多驱动问题
   - 修改 `pe.sv` 代码
   - 运行 VCS 仿真验证

2. **PE 模块测试通过**
   - 运行 `make pe` 测试
   - 分析波形（Verdi）
   - 验证 MAC 运算正确性

3. **理解 PE 原理**
   - 学习 Weight Stationary 数据流
   - 理解 Q8.8 定点数运算
   - 准备面试问答（3个）

### 本周目标（Week 1）
- [ ] PE 模块完全理解并测试通过
- [ ] Systolic Array 理解
- [ ] 创建 tb_systolic.sv
- [ ] 运行 Systolic Array 测试

### 下周目标（Week 2）
- [ ] VPU 模块理解
- [ ] Control Unit 理解
- [ ] 创建 Golden Model (Python)
- [ ] Phase 1 总结

### 里程碑
| 里程碑 | 时间 | 验收标准 |
|--------|------|----------|
| **M1** | Week 2 | PE + Systolic 测试通过 |
| **M2** | Week 4 | ECC + Sparse 功能完成 |
| **M3** | Week 6 | 系统集成测试通过 |
| **M4** | Week 8 | UVM 覆盖率 > 90% |
| **M5** | Week 10 | 综合 PPA 数据 |
| **M6** | Week 12 | 完整文档 + 面试准备 |

---

## 🔗 关键资源

### 核心项目
- **tiny-tpu-v2**: https://github.com/tiny-tpu-v2/tiny-tpu
- **文档网站**: https://tinytpu.com
- **本地路径**: `/home/jjt/Titan_TPU_V2/_vendor/tiny-tpu-v2`

### AXI 库（待下载）
- **TAXI** (首选): https://github.com/fpganinja/taxi
- **pulp-axi**: https://github.com/pulp-platform/axi
- **wb2axip**: https://github.com/ZipCPU/wb2axip

### 深入学习（后续扩展）
- **Gemmini** (学术): https://github.com/ucb-bar/gemmini
- **NVDLA** (工业): https://github.com/nvdla/hw
- **Ztachip** (FPGA): https://github.com/ztachip/ztachip
- **TVM-VTA** (编译器): https://github.com/apache/tvm-vta

### 学习资料
- **TPU 论文**: 搜索 "In-Datacenter Performance Analysis of a TPU"
- **Systolic Array**: 搜索 "Why Systolic Architectures"
- **AXI 协议**: ARM AMBA AXI Protocol Specification
- **Hamming 码**: 搜索 "Hamming SECDED tutorial"

---

## 📝 更新日志

### 2026-01-18
- ✅ 创建 CLAUDE.md 总览文档
- ✅ 整理项目结构和进度
- ✅ 明确 AI 工具使用策略
- 🔄 当前任务：修复 PE 模块 Bug

### 2025-01-16
- ✅ 完成12份项目文档
- ✅ 环境配置完成
- ✅ 下载核心代码库

---

## 🎯 简历亮点（一句话）

> "基于开源 TPU 项目进行深度魔改，添加了 **ECC 容错**（Hamming SECDED，符合车规 ASIL-B）、**稀疏化优化**（零值跳过 + Clock Gating，功耗降低 40%）、**AXI 总线接口**（工业级 SoC 集成），使用 **VCS 仿真**、**UVM 验证**、**DC 综合**，有完整的 **PPA 数据**和**覆盖率报告**。"

---

## 📞 快速命令

### 环境激活
```bash
cd /home/jjt/Titan_TPU_V2
source env_setup.sh
# 或使用别名
tpu-env
```

### VCS 仿真
```bash
cd sim/vcs
make pe          # PE 模块测试
make systolic    # Systolic Array 测试
make clean       # 清理
```

### Claude API 使用
```bash
claude-debug "错误信息" 文件路径    # 调试错误
claude-review 文件路径             # 代码审查
claude-explain 文件路径            # 解释代码
claude-ask "问题"                  # 通用问题
```

### Git 操作
```bash
git status                         # 查看状态
git add .                          # 添加所有改动
git commit -m "feat(pe): 修复多驱动问题"
git log --oneline                  # 查看历史
```

---

## ⚠️ 注意事项

1. **每次新对话**：粘贴 `claude/01_MASTER_INSTRUCTIONS.md` 或本文件
2. **每日更新**：更新进度到 `claude/titan_tpu_docs/07_PROGRESS_TRACKER.md`
3. **遇到Bug**：记录到 `claude/titan_tpu_docs/08_DEBUG_LOG.md`
4. **Git提交**：每完成一个功能就提交
5. **文档同步**：代码改了，文档也要更新

---

*最后更新: 2026-01-18 | 版本: v1.0*
