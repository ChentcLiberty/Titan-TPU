# 06 - AI 工具使用手册

> 详细说明项目中使用的所有 AI 工具、分工和最佳实践

---

## 📋 目录

1. [工具总览](#1-工具总览)
2. [Claude Opus (网页版)](#2-claude-opus-网页版)
3. [Claude API (Linux)](#3-claude-api-linux)
4. [Gemini Pro](#4-gemini-pro)
5. [NotebookLM](#5-notebooklm)
6. [ChatGPT](#6-chatgpt)
7. [问题分流决策树](#7-问题分流决策树)
8. [Prompt 模板库](#8-prompt-模板库)

---

## 1. 工具总览

### 1.1 工具清单

| 工具 | 平台 | 地址 | 主要用途 | 优先级 |
|------|------|------|----------|--------|
| **Claude Opus** | 网页 | claude.ai | 架构设计、复杂问题 | ⭐⭐⭐⭐⭐ |
| **Claude API** | Linux | www.zz166.cn | VCS调试、代码修复 | ⭐⭐⭐⭐⭐ |
| **Gemini Pro** | 网页 | gemini.google.com | 代码审查、长文件 | ⭐⭐⭐⭐ |
| **NotebookLM** | 网页 | notebooklm.google.com | 论文学习、原理 | ⭐⭐⭐⭐ |
| **ChatGPT** | 网页 | chat.openai.com | 简单问题 | ⭐⭐⭐ |

### 1.2 分工原则

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           AI 工具分工矩阵                                    │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  问题复杂度 ↑                                                               │
│       │                                                                     │
│  高   │    ┌─────────────────┐                                             │
│       │    │  Claude Opus    │  ← 架构设计、系统集成                        │
│       │    │  (网页版)       │  ← 复杂 Bug、设计评审                        │
│       │    └─────────────────┘                                             │
│       │                                                                     │
│  中   │    ┌─────────────────┐   ┌─────────────────┐                       │
│       │    │  Claude API    │   │  Gemini Pro     │                       │
│       │    │  (Linux)       │   │                 │                       │
│       │    │ VCS错误、修复   │   │ 代码审查、分析  │                       │
│       │    └─────────────────┘   └─────────────────┘                       │
│       │                                                                     │
│  低   │    ┌─────────────────┐   ┌─────────────────┐                       │
│       │    │  NotebookLM    │   │  ChatGPT       │                       │
│       │    │ 论文、原理     │   │ 简单问题       │                       │
│       │    └─────────────────┘   └─────────────────┘                       │
│       │                                                                     │
│       └─────────────────────────────────────────────────────────→ 响应速度  │
│                慢                                           快              │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Claude Opus (网页版)

### 2.1 基本信息

```yaml
地址: https://claude.ai
账号: [你的账号]
用途: 架构设计、复杂问题、项目指导
特点: 最强推理能力，上下文长
```

### 2.2 使用场景

| 场景 | 示例 | 说明 |
|------|------|------|
| **架构设计** | "设计 ECC 模块架构" | 复杂的系统级设计 |
| **复杂 Bug** | "这个时序问题怎么解决" | 需要深入分析的问题 |
| **设计评审** | "评审这个架构方案" | 需要经验判断的问题 |
| **项目规划** | "帮我规划下周任务" | 项目管理相关 |
| **面试准备** | "这个问题怎么回答" | 需要深度思考的问题 |

### 2.3 最佳实践

1. **使用 Project 功能**
   - 创建 "Titan-TPU V2" Project
   - 把 `01_MASTER_INSTRUCTIONS.md` 放到 Instructions
   - 所有对话都在这个 Project 中进行

2. **提供充分上下文**
   - 每次新对话都粘贴当前进度
   - 遇到 Bug 要粘贴完整错误信息
   - 提供相关代码

3. **要求结构化输出**
   - 明确要求输出格式
   - 要求提供代码、文档、命令

### 2.4 常用 Prompt

```markdown
# 架构设计
请设计 [模块名] 模块，要求：
1. 功能需求: [描述]
2. 接口: [约束]
3. 性能: [目标]

请提供：架构图、接口定义、RTL代码、验证策略

# 复杂 Bug
我遇到了 [问题描述]

错误信息:
```
[错误]
```

代码:
```systemverilog
[代码]
```

请分析原因并提供修复方案

# 设计评审
请评审以下设计方案:
[方案描述]

评审要点：合理性、可行性、风险点、改进建议
```

---

## 3. Claude API (Linux)

### 3.1 基本信息

```yaml
地址: www.zz166.cn
脚本: /home/jjt/Titan_TPU_V2/claude_debug.py
用途: VCS调试、代码修复、快速问答
特点: 本地命令行，快速响应
```

### 3.2 命令列表

| 命令 | 用法 | 场景 |
|------|------|------|
| `debug` | `claude-debug "错误" [文件]` | VCS编译/仿真错误 |
| `review` | `claude-review 文件` | 代码审查 |
| `explain` | `claude-explain 文件` | 解释代码 |
| `design` | `claude-design "任务"` | 设计模块 |
| `ask` | `claude-ask "问题"` | 通用问题 |

### 3.3 使用示例

```bash
# 激活环境
tpu-env

# 调试 VCS 错误
claude-debug "Error-[ICPD] weight_reg_active" _vendor/tiny-tpu-v2/src/pe.sv

# 代码审查
claude-review _vendor/tiny-tpu-v2/src/pe.sv

# 解释代码
claude-explain _vendor/tiny-tpu-v2/src/systolic.sv

# 设计模块
claude-design "设计一个 Hamming(39,32) ECC 编码器"

# 通用问题
claude-ask "什么是 Weight Stationary 数据流"
```

### 3.4 最佳实践

1. **第一时间用它调试 VCS 错误**
   - 比网页版快
   - 自动保存日志

2. **带上代码文件**
   - 可以自动读取文件内容
   - 分析更准确

3. **查看日志**
   - 日志保存在 `/home/jjt/Titan_TPU_V2/logs/claude_sessions/`
   - 可以回顾历史解答

---

## 4. Gemini Pro

### 4.1 基本信息

```yaml
地址: https://gemini.google.com 或 https://aistudio.google.com
用途: 代码审查、长文件分析
特点: 上下文窗口大 (100万tokens)，适合长代码
```

### 4.2 使用场景

| 场景 | 说明 |
|------|------|
| **长代码审查** | 一次粘贴整个文件 |
| **多文件分析** | 同时分析多个相关文件 |
| **代码对比** | 对比两个版本的差异 |
| **重构建议** | 大规模代码重构 |

### 4.3 常用 Prompt

```markdown
# 代码审查
请审查以下 SystemVerilog 代码，检查:
1. 可综合性问题
2. 时序问题
3. 代码风格
4. 潜在 Bug

```systemverilog
[粘贴完整代码]
```

# 多文件分析
以下是 TPU 的核心模块，请分析数据流:

pe.sv:
```systemverilog
[代码]
```

systolic.sv:
```systemverilog
[代码]
```

# 重构建议
这是现有代码，我想 [目标]，请给出重构方案:
```systemverilog
[代码]
```
```

---

## 5. NotebookLM

### 5.1 基本信息

```yaml
地址: https://notebooklm.google.com
用途: 论文学习、原理理解
特点: 可以上传文档，针对文档问答
```

### 5.2 需要上传的文档

| 文档 | 获取方式 | 用途 |
|------|----------|------|
| TPU 论文 | 搜索 "In-Datacenter Performance Analysis of a TPU PDF" | 理解 TPU 架构 |
| Systolic Array 教程 | 搜索 "Systolic array tutorial PDF" | 理解数据流 |
| AXI 协议 | 搜索 "AMBA AXI Protocol PDF" | 学习 AXI |
| Hamming 码 | 搜索 "Hamming SECDED tutorial PDF" | 学习 ECC |
| UVM 手册 | 搜索 "UVM Cookbook PDF" | 学习验证 |

### 5.3 使用方法

1. **创建笔记本**
   - 创建 "TPU 学习" 笔记本
   - 上传相关文档

2. **问问题**
   ```
   - 用中文解释 Weight Stationary 数据流
   - TPU 的 Systolic Array 是如何工作的？
   - Hamming(39,32) 的编码原理是什么？
   ```

3. **生成摘要**
   - 可以让它生成文档摘要
   - 适合快速了解论文内容

---

## 6. ChatGPT

### 6.1 基本信息

```yaml
地址: https://chat.openai.com
用途: 简单问题、快速查询
特点: 响应快，适合简单问题
```

### 6.2 使用场景

| 场景 | 示例 |
|------|------|
| **语法问题** | "Verilog always_comb 和 always_ff 的区别" |
| **基础概念** | "什么是 Clock Gating" |
| **工具用法** | "VCS -debug_access+all 参数含义" |
| **快速查询** | "Makefile 怎么写并行编译" |

### 6.3 不适合的场景

- ❌ 复杂架构设计
- ❌ 长代码分析
- ❌ 需要准确性的问题
- ❌ 需要上下文的问题

---

## 7. 问题分流决策树

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           问题分流决策树                                     │
└─────────────────────────────────────────────────────────────────────────────┘

你遇到了什么问题?
│
├─── VCS 编译报错?
│    │
│    ├─── 简单错误 (语法、拼写)
│    │    └──→ Claude API: claude-debug "错误" file.sv
│    │
│    └─── 复杂错误 (时序、架构)
│         └──→ Claude Opus: 粘贴错误 + 代码，详细分析
│
├─── 需要理解代码?
│    │
│    ├─── 单个文件
│    │    └──→ Claude API: claude-explain file.sv
│    │
│    └─── 多个文件/系统级
│         └──→ Gemini Pro: 粘贴多个文件
│
├─── 需要学习原理?
│    │
│    ├─── 有论文/文档
│    │    └──→ NotebookLM: 上传文档问答
│    │
│    └─── 没有文档
│         └──→ Claude Opus: 详细讲解
│
├─── 需要设计模块?
│    │
│    ├─── 简单模块
│    │    └──→ Claude API: claude-design "任务"
│    │
│    └─── 复杂模块/系统
│         └──→ Claude Opus: 详细设计
│
├─── 需要代码审查?
│    │
│    ├─── 短代码 (<100行)
│    │    └──→ Claude API: claude-review file.sv
│    │
│    └─── 长代码 (>100行)
│         └──→ Gemini Pro: 粘贴完整代码
│
├─── 简单语法问题?
│    └──→ ChatGPT: 快速回答
│
└─── 项目规划/面试准备?
     └──→ Claude Opus: 详细讨论
```

---

## 8. Prompt 模板库

### 8.1 Debug 类

```markdown
# VCS 编译错误 (Claude API)
claude-debug "[完整错误信息]" [相关文件]

# 仿真结果错误 (Claude Opus)
仿真结果不对，预期 [预期]，实际 [实际]
代码: [粘贴]
请分析原因

# 时序不满足 (Claude Opus)
DC 报告时序违例: [粘贴报告]
请分析关键路径并给出优化方案
```

### 8.2 学习类

```markdown
# 解释代码 (Claude API)
claude-explain [文件路径]

# 学习概念 (NotebookLM)
用中文解释 [概念]，并举例说明

# 对比分析 (Gemini Pro)
对比 [A] 和 [B] 的区别，列表说明
```

### 8.3 设计类

```markdown
# 模块设计 (Claude Opus)
设计 [模块名]
功能: [描述]
接口: [约束]
请提供: 架构图、RTL代码、验证策略

# 快速设计 (Claude API)
claude-design "[简短描述]"
```

### 8.4 审查类

```markdown
# 代码审查 (Gemini Pro)
审查以下代码的可综合性、时序、风格:
```systemverilog
[代码]
```

# 快速审查 (Claude API)
claude-review [文件]
```

---

## 📌 使用检查清单

每天开始工作前:
- [ ] 确认 Claude API 可用 (`claude-ask "测试"`)
- [ ] 确认网络正常
- [ ] 打开 Claude Opus 标签页

遇到问题时:
- [ ] 按决策树选择工具
- [ ] 提供完整上下文
- [ ] 保存有价值的回答

---

*文档版本: v1.0 | 更新时间: 2025-01-16*
