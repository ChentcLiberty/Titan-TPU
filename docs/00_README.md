# TitanTPU 文档中心

> **最后更新**: 2026-01-22
> **文档版本**: v2.0
> **整理状态**: ✅ 已完成分类归档

---

## 📚 文档导航

### 01_core/ - 核心文档
**项目的核心文档和总览**

- `PROJECTS_CLONE_LIST.md` - 项目克隆列表

**快速入口**:
- 新手入门 → 先看核心文档
- 项目总览 → 了解项目定位和目标

---

### 02_guides/ - 使用指南
**工具使用和环境配置指南**

- `AI_TOOLS_GUIDE.md` - AI 工具使用指南
- `CLAUDE_CODE_SETUP.md` - Claude Code 环境配置
- `SESSION_TEMPLATES.md` - 会话模板

**适用场景**:
- 配置开发环境
- 学习 AI 工具使用
- 管理对话会话

---

### 03_technical/ - 技术文档
**项目的技术参考和学习路线**

- `PROJECT_OVERVIEW.md` - 项目总览
- `TECHNICAL_REFERENCE.md` - 技术参考手册
- `WORKFLOW_DETAILED.md` - 详细工作流程
- `LEARNING_ROADMAP.md` - 学习路线图

**适用场景**:
- 深入理解技术细节
- 规划学习路径
- 查阅技术参考

---

### 04_progress/ - 进度追踪
**项目进度、Debug 日志和会话记录**

- `PROGRESS_TRACKER.md` - 进度追踪
- `DEBUG_LOG.md` - Debug 日志
- `SESSION_PROGRESS.md` - 会话进度记录

**适用场景**:
- 查看项目进度
- 回顾 Debug 历史
- 追踪会话记录

---

### 05_interview/ - 面试准备
**面试相关的准备材料**

- `INTERVIEW_PREP.md` - 面试准备手册

**适用场景**:
- 准备技术面试
- 整理项目亮点
- 准备面试问答

---

### 06_analysis/ - 技术分析
**深度技术分析文档**

- `pe_weight_stationary_analysis.md` - PE 权重固定架构分析

**适用场景**:
- 深入理解模块原理
- 技术方案分析
- 设计决策参考

---

### 07_future/ - 未来改进计划
**项目的未来改进和优化计划**

#### enhancements/ - 功能增强
- `01_pe_accept_w_out.md` - PE 权重加载机制改进

#### optimizations/ - 性能优化
- `README.md` - 优化计划总览
- `01_saturation_overflow_plan.md` - 饱和溢出处理计划

**适用场景**:
- 规划未来改进
- 设计新特性
- 优化性能

---

## 🗂️ 文档分类说明

### 按用途分类

| 分类 | 目录 | 用途 |
|------|------|------|
| **入门** | 01_core/ | 快速了解项目 |
| **配置** | 02_guides/ | 环境配置和工具使用 |
| **学习** | 03_technical/ | 技术学习和参考 |
| **追踪** | 04_progress/ | 进度和问题追踪 |
| **面试** | 05_interview/ | 面试准备 |
| **深入** | 06_analysis/ | 深度技术分析 |
| **规划** | 07_future/ | 未来改进计划 |

### 按阶段分类

| 阶段 | 推荐阅读 |
|------|----------|
| **Phase 0: 入门** | 01_core/, 02_guides/ |
| **Phase 1: 学习** | 03_technical/, 06_analysis/ |
| **Phase 2: 开发** | 04_progress/, 07_future/ |
| **Phase 3: 面试** | 05_interview/ |

---

## 📖 推荐阅读顺序

### 新手入门路径
1. `01_core/PROJECTS_CLONE_LIST.md` - 了解项目列表
2. `02_guides/CLAUDE_CODE_SETUP.md` - 配置环境
3. `03_technical/PROJECT_OVERVIEW.md` - 理解项目
4. `03_technical/LEARNING_ROADMAP.md` - 规划学习

### 开发者路径
1. `03_technical/TECHNICAL_REFERENCE.md` - 技术参考
2. `06_analysis/pe_weight_stationary_analysis.md` - 深入分析
3. `04_progress/PROGRESS_TRACKER.md` - 追踪进度
4. `07_future/` - 规划改进

### 面试准备路径
1. `05_interview/INTERVIEW_PREP.md` - 面试准备
2. `06_analysis/` - 技术深度
3. `07_future/enhancements/` - 改进亮点

---

## 🔍 快速查找

### 按关键词查找

| 关键词 | 相关文档 |
|--------|----------|
| **环境配置** | 02_guides/CLAUDE_CODE_SETUP.md |
| **AI 工具** | 02_guides/AI_TOOLS_GUIDE.md |
| **技术参考** | 03_technical/TECHNICAL_REFERENCE.md |
| **学习路线** | 03_technical/LEARNING_ROADMAP.md |
| **进度追踪** | 04_progress/PROGRESS_TRACKER.md |
| **Debug** | 04_progress/DEBUG_LOG.md |
| **面试** | 05_interview/INTERVIEW_PREP.md |
| **PE 分析** | 06_analysis/pe_weight_stationary_analysis.md |
| **未来改进** | 07_future/ |

---

## 📝 文档维护

### 更新规则
1. **每次重大改动**: 更新相关文档
2. **每周**: 更新进度追踪
3. **每个里程碑**: 更新技术文档
4. **面试前**: 更新面试准备材料

### 文档命名规范
- 核心文档: 大写字母 + 下划线 (如 `PROJECT_OVERVIEW.md`)
- 分析文档: 小写字母 + 下划线 (如 `pe_weight_stationary_analysis.md`)
- 编号文档: 数字前缀 (如 `01_pe_accept_w_out.md`)

---

## 🔗 相关资源

### 外部文档
- **Gemini/** - 参考资料库（PDF、论文等）
- **claude/** - Claude 工具配置（保持原样）

### 代码目录
- **rtl/** - RTL 代码
- **tb/** - Testbench
- **sim/** - 仿真脚本
- **syn/** - 综合脚本

---

*文档中心创建: 2026-01-22*
*整理完成: 2026-01-22*
*维护者: Chen Weidong*
