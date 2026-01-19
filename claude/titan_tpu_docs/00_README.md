# 🚀 Titan-TPU V2 完整项目移植包

> **版本**: v4.0 | **日期**: 2025-01-16 | **作者**: JJT

---

## 📦 文件清单 (共 12 个文档)

| 序号 | 文件名 | 用途 | 优先级 |
|------|--------|------|--------|
| 01 | `01_MASTER_INSTRUCTIONS.md` | **主 Instructions - 每次新对话必读** | ⭐⭐⭐⭐⭐ |
| 02 | `02_PROJECT_OVERVIEW.md` | 项目总览、资源列表、架构图 | ⭐⭐⭐⭐⭐ |
| 03 | `03_TECHNICAL_REFERENCE.md` | 技术规格、代码结构、接口定义 | ⭐⭐⭐⭐ |
| 04 | `04_WORKFLOW_DETAILED.md` | 12周详细工作流、每日任务 | ⭐⭐⭐⭐ |
| 05 | `05_CLAUDE_CODE_SETUP.md` | CentOS7 Claude Code 完整配置 | ⭐⭐⭐⭐⭐ |
| 06 | `06_AI_TOOLS_GUIDE.md` | AI工具使用手册、分工、Prompt模板 | ⭐⭐⭐⭐ |
| 07 | `07_PROGRESS_TRACKER.md` | 进度追踪表、检查清单 | ⭐⭐⭐⭐ |
| 08 | `08_DEBUG_LOG.md` | Debug日志模板、常见问题 | ⭐⭐⭐ |
| 09 | `09_INTERVIEW_PREP.md` | 面试问答、话术、故事准备 | ⭐⭐⭐⭐ |
| 10 | `10_LEARNING_ROADMAP.md` | 学习路线、资源链接、扩展方向 | ⭐⭐⭐ |
| 11 | `11_SESSION_TEMPLATES.md` | 对话模板集合、交接模板 | ⭐⭐⭐⭐⭐ |
| 12 | `12_SCRIPTS_COLLECTION.md` | 所有脚本源码集合 | ⭐⭐⭐⭐ |

---

## 🎯 使用场景速查

### 场景 1: 开启新的 Claude 对话
```
1. 打开 01_MASTER_INSTRUCTIONS.md
2. 复制全部内容到 Claude Project Instructions
3. 打开 11_SESSION_TEMPLATES.md
4. 复制 "新对话启动模板" 作为第一条消息
```

### 场景 2: 当前对话快满了
```
1. 让 Claude 生成 "会话交接摘要"
2. 更新 07_PROGRESS_TRACKER.md
3. 开新对话，粘贴 Instructions + 交接摘要
```

### 场景 3: 遇到 Bug 需要调试
```
1. 使用 Linux 终端的 claude-debug 命令
2. 或复制错误信息到 Claude 对话
3. 记录到 08_DEBUG_LOG.md
```

### 场景 4: 准备面试
```
1. 阅读 09_INTERVIEW_PREP.md
2. 准备 5 个核心问题的回答
3. 整理项目亮点和数据
```

---

## 📋 快速开始

### Step 1: 在 CentOS 7 上设置环境
```bash
# 解压文档包
tar -xzf titan_tpu_docs.tar.gz
cd titan_tpu_docs

# 查看 Claude Code 设置
cat 05_CLAUDE_CODE_SETUP.md

# 运行设置脚本 (从 12_SCRIPTS_COLLECTION.md 提取)
```

### Step 2: 配置 Claude Project
```
1. 打开 claude.ai
2. 创建新 Project: "Titan-TPU V2"
3. 点击 "Project Instructions"
4. 粘贴 01_MASTER_INSTRUCTIONS.md 的全部内容
5. 保存
```

### Step 3: 开始工作
```
1. 在 Project 中开新对话
2. 粘贴 11_SESSION_TEMPLATES.md 中的启动模板
3. 开始你的任务
```

---

## 🔄 文档更新规则

### 每日更新
- `07_PROGRESS_TRACKER.md` - 更新当日完成的任务
- `08_DEBUG_LOG.md` - 记录新发现的 Bug

### 每周更新
- `04_WORKFLOW_DETAILED.md` - 调整下周计划
- `01_MASTER_INSTRUCTIONS.md` - 更新当前进度状态

### 里程碑更新
- `09_INTERVIEW_PREP.md` - 添加新的项目亮点
- `03_TECHNICAL_REFERENCE.md` - 更新技术细节

---

## 📚 文档依赖关系

```
01_MASTER_INSTRUCTIONS.md (核心)
    │
    ├── 02_PROJECT_OVERVIEW.md (背景知识)
    │       └── 10_LEARNING_ROADMAP.md
    │
    ├── 03_TECHNICAL_REFERENCE.md (技术细节)
    │
    ├── 04_WORKFLOW_DETAILED.md (执行计划)
    │       └── 07_PROGRESS_TRACKER.md
    │
    ├── 05_CLAUDE_CODE_SETUP.md (工具配置)
    │       └── 06_AI_TOOLS_GUIDE.md
    │
    └── 11_SESSION_TEMPLATES.md (对话管理)
            └── 08_DEBUG_LOG.md
```

---

*项目移植包 v4.0 - 持续更新中*
