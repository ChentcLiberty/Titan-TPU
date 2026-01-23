# 项目 Clone 清单

> **最后更新**: 2026-01-18
> **用途**: 记录所有需要 clone 的开源项目，按优先级和阶段分类

---

## 📋 目录

- [第1优先级 - 立即需要](#第1优先级---立即需要phase-1-3)
- [第2优先级 - AXI升级](#第2优先级---axi升级phase-3)
- [第3优先级 - 深入学习](#第3优先级---深入学习phase-6秋招准备)
- [Clone 执行计划](#clone-执行计划)
- [项目优先级总结](#项目优先级总结)
- [存储空间估算](#存储空间估算)

---

## 🔴 第1优先级 - 立即需要（Phase 1-3）

### 1. **tiny-tpu-v2** ⭐⭐⭐⭐⭐

```bash
# 状态：✅ 已下载
# 位置：/home/jjt/Titan_TPU_V2/_vendor/tiny-tpu-v2
git clone https://github.com/tiny-tpu-v2/tiny-tpu.git
```

**项目信息**：
- **GitHub**: https://github.com/tiny-tpu-v2/tiny-tpu
- **文档网站**: https://tinytpu.com
- **Stars**: 1000+
- **语言**: SystemVerilog (46%) + Python (45%)
- **规模**: ~2000行，17个SV文件
- **用途**: 核心TPU代码，你的魔改基础
- **阶段**: Phase 1-6 全程使用

**核心文件清单**：
| 文件 | 功能 | 重要性 | 行数 |
|------|------|--------|------|
| `pe.sv` | Processing Element (MAC单元) | ⭐⭐⭐⭐⭐ | ~100 |
| `systolic.sv` | 2×2 脉动阵列 | ⭐⭐⭐⭐⭐ | ~200 |
| `vpu.sv` | 向量处理单元顶层 | ⭐⭐⭐⭐ | ~150 |
| `unified_buffer.sv` | 统一缓存 | ⭐⭐⭐⭐ | ~100 |
| `control_unit.sv` | 94位ISA控制器 | ⭐⭐⭐⭐ | ~300 |
| `tpu.sv` | TPU顶层 | ⭐⭐⭐⭐⭐ | ~200 |
| `fixedpoint.sv` | Q8.8定点运算库 | ⭐⭐⭐ | ~400 |

**为什么选择它**：
1. ✅ 代码量适中：~2000行，一个月能读完
2. ✅ SystemVerilog：面试标配语言
3. ✅ 文档极好：有专门网站 tinytpu.com
4. ✅ 功能完整：前向+反向传播都有
5. ✅ 94位ISA：展示系统设计能力
6. ✅ 活跃维护：持续更新中

---

### 2. **verilog-axi** ⭐⭐⭐⭐

```bash
# 状态：✅ 已下载
# 位置：/home/jjt/Titan_TPU_V2/_vendor/verilog-axi
git clone https://github.com/alexforencich/verilog-axi.git
```

**项目信息**：
- **GitHub**: https://github.com/alexforencich/verilog-axi
- **作者**: Alex Forencich
- **语言**: Verilog
- **用途**: 基础AXI接口库
- **阶段**: Phase 3（系统集成）

**说明**：
- 这是基础版本，后续会升级为 TAXI（SystemVerilog版）
- 可以先��它理解 AXI 协议
- 代码风格清晰，适合学习

---

## 🟡 第2优先级 - AXI升级（Phase 3）

### 3. **TAXI** ⭐⭐⭐⭐⭐ (首选)

```bash
# 状态：📋 待下载
# 建议时间：Week 5（系统集成前）
cd /home/jjt/Titan_TPU_V2/_vendor
git clone https://github.com/fpganinja/taxi.git
```

**项目信息**：
- **GitHub**: https://github.com/fpganinja/taxi
- **作者**: Alex Forencich（同 verilog-axi）
- **语言**: SystemVerilog
- **特点**: verilog-axi 的 SV 继任者

**为什么首选**：
- ✅ 同一作者，API 兼容
- ✅ 完全 SystemVerilog，与项目语言一致
- ✅ 可直接替换 verilog-axi
- ✅ 代码风格现代

**关键模块**：
```
taxi/
├── axi_adapter.sv
├── axi_crossbar.sv
├── axi_interconnect.sv
├── axi_ram.sv
└── axi_register.sv
```

**使用场景**：
- Phase 3 系统集成
- 添加 AXI4-Lite 接口
- SoC 集成演示

---

### 4. **pulp-axi** ⭐⭐⭐⭐

```bash
# 状态：📋 待下载（可选）
# 建议时间：Week 5（如果需要高性能方案）
cd /home/jjt/Titan_TPU_V2/_vendor
git clone https://github.com/pulp-platform/axi.git pulp-axi
```

**项目信息**：
- **GitHub**: https://github.com/pulp-platform/axi
- **来源**: ETH Zurich PULP 团队
- **语言**: SystemVerilog
- **特点**: 现代高性能 SoC 首选

**适用场景**：
- 需要高性能 AXI 交叉开关
- 复杂 SoC 集成
- 面试 ARM/高通等公司

**优势**：
- 学术界认可度高（ETH Zurich）
- 代码质量高
- 文档完善

---

### 5. **wb2axip** ⭐⭐⭐

```bash
# 状态：📋 待下载（可选）
# 建议时间：Week 5（如果需要形式化验证）
cd /home/jjt/Titan_TPU_V2/_vendor
git clone https://github.com/ZipCPU/wb2axip.git
```

**项目信息**：
- **GitHub**: https://github.com/ZipCPU/wb2axip
- **作者**: ZipCPU (业界知名)
- **语言**: Verilog
- **特点**: 形式化验证，极度健壮

**适用场景**：
- 强调设计可靠性
- 需要讲形式化验证
- Wishbone ↔ AXI 桥接

**优势**：
- 形式化验证保证正确性
- 代码极度健壮
- 适合讲"可靠性"故事

---

## 🟢 第3优先级 - 深入学习（Phase 6+，秋招准备）

### 6. **Gemmini** ⭐⭐⭐⭐⭐ (学术最强)

```bash
# 状态：📋 待下载
# 建议时间：Week 13+（秋招准备阶段）
mkdir -p /home/jjt/learning/ai-accelerators
cd /home/jjt/learning/ai-accelerators
git clone https://github.com/ucb-bar/gemmini.git
```

**项目信息**：
- **GitHub**: https://github.com/ucb-bar/gemmini
- **来源**: UC Berkeley
- **生态**: Chipyard / RISC-V
- **语言**: Chisel → Verilog

**核心价值**：
- 🏆 体系结构研究标杆
- 🏆 软硬协同设计 (RoCC 接口)
- 🏆 可发顶会论文 (ISCA/MICRO/HPCA)
- 🏆 学术界认可度最高

**学习路径**：
```
Week 1: 阅读 Gemmini 论文
Week 2: 搭建 Chipyard 环境
Week 3: 跑通 Gemmini 仿真
Week 4-5: 修改参数生成变体
Week 6: 对比分析 vs Titan-TPU
```

**关键论文**：
- "Gemmini: An Agile Systolic Array Generator Enabling Systematic Evaluations of Deep-Learning Architectures" (DAC 2021)

**面试价值**：
- 展示学术研究能力
- 理解 Chisel 硬件生成器
- 软硬协同设计经验
- 适合申请研究型岗位

---

### 7. **NVDLA** ⭐⭐⭐⭐⭐ (工业标杆)

```bash
# 状态：📋 待下载
# 建议时间：Week 13+（秋招准备阶段）
cd /home/jjt/learning/ai-accelerators
git clone https://github.com/nvdla/hw.git nvdla
```

**项目信息**：
- **GitHub**: https://github.com/nvdla/hw
- **官网**: https://nvdla.org
- **来源**: NVIDIA
- **规模**: ~50000 行 Verilog

**核心价值**：
- 🏭 工业级 NPU 设计规范
- 🏭 完整 CNN 加速器架构
- 🏭 文档是学习正规设计的最佳参考
- 🏭 面试 NVIDIA/AMD 必看

**重点模块**：
| 模块 | 功能 | 学习价值 |
|------|------|----------|
| CMAC | 卷积核心 | 理解 MAC 阵列 |
| SDP | 后处理 | 激活/池化 |
| PDP | 池化 | Pooling 实现 |
| CDMA | DMA | 数据搬运 |

**学习重点**：
- 工业级代码规范
- 模块化设计
- 接口标准化
- 文档规范

**面试价值**：
- 展示工业级项目经验
- 理解完整 NPU 架构
- 适合申请 NVIDIA/AMD/寒武纪

---

### 8. **Ztachip** ⭐⭐⭐⭐ (FPGA实战)

```bash
# 状态：📋 待下载
# 建议时间：Week 13+（如果需要FPGA验证）
cd /home/jjt/learning/ai-accelerators
git clone https://github.com/ztachip/ztachip.git
```

**项目信息**：
- **GitHub**: https://github.com/ztachip/ztachip
- **特点**: 基于 RISC-V 的轻量级 AI 加速器
- **平台**: Artix-7 等低端 FPGA
- **应用**: Vision AI

**核心价值**：
- 💡 可以在便宜 FPGA 上跑通
- 💡 有完整的视觉 Demo
- 💡 适合硬件验证和演示

**适用场景**：
- 需要实际硬件演示
- 学习 FPGA 实现
- 展示端到端能力

**面试价值**：
- 展示 FPGA 实战经验
- 有实际硬件演示
- 适合申请 FPGA 相关岗位

---

### 9. **TVM-VTA** ⭐⭐⭐⭐ (编译器全栈)

```bash
# 状态：📋 待下载
# 建议时间：Week 20+（第4层扩展）
cd /home/jjt/learning/ai-accelerators
git clone https://github.com/apache/tvm.git
# VTA 是 TVM 的一部分
```

**项目信息**：
- **GitHub**: https://github.com/apache/tvm-vta
- **官网**: https://tvm.apache.org
- **特点**: 框架→编译器→硬件 全流程
- **语言**: Chisel + Python

**核心价值**：
- 🔗 打通 PyTorch/TensorFlow → 编译器 → 硬件
- 🔗 展示软硬协同能力
- 🔗 适合系统架构师方向

**学习内容**：
- TVM 编译器原理
- 算子优化
- 硬件后端适配
- 端到端性能优化

**面试价值**：
- 展示全栈能力
- 理解编译器优化
- 适合申请系统架构师岗位

---

## 📅 Clone 执行计划

### 立即执行（本周）

```bash
# 检查已有项目
cd /home/jjt/Titan_TPU_V2/_vendor
ls -la tiny-tpu-v2/    # 应该已存在
ls -la verilog-axi/    # 应该已存在

# 如果不存在，执行：
git clone https://github.com/tiny-tpu-v2/tiny-tpu.git tiny-tpu-v2
git clone https://github.com/alexforencich/verilog-axi.git
```

---

### Week 5 执行（系统集成前）

```bash
cd /home/jjt/Titan_TPU_V2/_vendor

# Clone TAXI（首选）
echo "Cloning TAXI..."
git clone https://github.com/fpganinja/taxi.git

# 可选：如果需要对比不同AXI库
echo "Cloning pulp-axi (optional)..."
git clone https://github.com/pulp-platform/axi.git pulp-axi

echo "Cloning wb2axip (optional)..."
git clone https://github.com/ZipCPU/wb2axip.git

echo "✅ AXI libraries cloned!"
```

---

### Week 13+ 执行（秋招准备）

```bash
# 创建学习目录
mkdir -p /home/jjt/learning/ai-accelerators
cd /home/jjt/learning/ai-accelerators

# 学术研究
echo "Cloning Gemmini..."
git clone https://github.com/ucb-bar/gemmini.git

# 工业参考
echo "Cloning NVDLA..."
git clone https://github.com/nvdla/hw.git nvdla

# FPGA实战
echo "Cloning Ztachip..."
git clone https://github.com/ztachip/ztachip.git

# 编译器全栈（可选）
echo "Cloning TVM..."
git clone https://github.com/apache/tvm.git

echo "✅ All learning projects cloned!"
```

---

## 📊 项目优先级总结

| 项目 | 优先级 | 何时需要 | 规模 | 语言 | 用途 |
|------|--------|----------|------|------|------|
| **tiny-tpu-v2** | ⭐⭐⭐⭐⭐ | 立即 | 2K行 | SV | 核心代码 |
| **verilog-axi** | ⭐⭐⭐⭐ | 立即 | 中等 | Verilog | 基础AXI |
| **TAXI** | ⭐⭐⭐⭐⭐ | Week 5 | 中等 | SV | AXI升级（首选） |
| **pulp-axi** | ⭐⭐⭐⭐ | Week 5 | 中等 | SV | 可选AXI（高性能） |
| **wb2axip** | ⭐⭐⭐ | Week 5 | 中等 | Verilog | 可选AXI（形式化） |
| **Gemmini** | ⭐⭐⭐⭐⭐ | Week 13+ | 大型 | Chisel | 学术研究 |
| **NVDLA** | ⭐⭐⭐⭐⭐ | Week 13+ | 50K行 | Verilog | 工业参考 |
| **Ztachip** | ⭐⭐⭐⭐ | Week 13+ | 中等 | SV | FPGA实战 |
| **TVM-VTA** | ⭐⭐⭐⭐ | Week 20+ | 大型 | Chisel+Py | 编译器全栈 |

---

## 💾 存储空间估算

```
tiny-tpu-v2:    ~10 MB
verilog-axi:    ~5 MB
TAXI:           ~5 MB
pulp-axi:       ~20 MB
wb2axip:        ~10 MB
Gemmini:        ~50 MB
NVDLA:          ~100 MB
Ztachip:        ~30 MB
TVM:            ~200 MB
─────────────────────────
总计:           ~430 MB
```

**建议**：
- 预留 **1GB** 空间（包括编译产物）
- 定期清理编译缓存
- 使用 `git clone --depth 1` 减少空间（如果不需要完整历史）

---

## 🎯 使用建议

### 1. 不要一次性全部 clone
- ❌ 避免混乱和存储浪费
- ✅ 按阶段需要逐步 clone
- ✅ 保持项目目录整洁

### 2. 按阶段 clone
```
Phase 1-2 (Week 1-4):
  → 只用 tiny-tpu-v2

Phase 3 (Week 5-6):
  → 添加 TAXI

Phase 6+ (Week 13+):
  → 添加学习项目（Gemmini/NVDLA等）
```

### 3. 创建合理的目录结构
```
/home/jjt/
├── Titan_TPU_V2/              # 主项目
│   └── _vendor/               # 核心依赖
│       ├── tiny-tpu-v2/       # ✅
│       ├── verilog-axi/       # ✅
│       └── taxi/              # Week 5
│
└── learning/                  # 学习项目
    └── ai-accelerators/       # Week 13+
        ├── gemmini/
        ├── nvdla/
        ├── ztachip/
        └── tvm/
```

### 4. 使用浅克隆节省空间（可选）
```bash
# 只克隆最新版本，不要完整历史
git clone --depth 1 https://github.com/xxx/xxx.git

# 优点：节省空间和时间
# 缺点：无法查看历史提交
```

### 5. 定期更新项目
```bash
# 进入项目目录
cd /home/jjt/Titan_TPU_V2/_vendor/tiny-tpu-v2

# 拉取最新更新
git pull origin main

# 查看更新内容
git log --oneline -10
```

---

## 📝 检查清单

### Phase 1-2 检查（当前）
- [x] tiny-tpu-v2 已下载
- [x] verilog-axi 已下载
- [ ] 验证项目可编译
- [ ] 阅读核心代码

### Phase 3 检查（Week 5）
- [ ] TAXI 已下载
- [ ] 理解 AXI 协议
- [ ] 测试 AXI 模块

### Phase 6+ 检查（Week 13+）
- [ ] Gemmini 已下载
- [ ] NVDLA 已下载
- [ ] 选择性下载 Ztachip/TVM
- [ ] 开始深入学习

---

## 🔗 快速链接

### 核心项目
- tiny-tpu-v2: https://github.com/tiny-tpu-v2/tiny-tpu
- 文档网站: https://tinytpu.com

### AXI 库
- TAXI: https://github.com/fpganinja/taxi
- pulp-axi: https://github.com/pulp-platform/axi
- wb2axip: https://github.com/ZipCPU/wb2axip
- verilog-axi: https://github.com/alexforencich/verilog-axi

### 学习项目
- Gemmini: https://github.com/ucb-bar/gemmini
- NVDLA: https://github.com/nvdla/hw
- NVDLA 官网: https://nvdla.org
- Ztachip: https://github.com/ztachip/ztachip
- TVM: https://github.com/apache/tvm
- TVM 官网: https://tvm.apache.org

---

## 📌 更新日志

### 2026-01-18
- ✅ 创建项目 clone 清单
- ✅ 整理9个核心项目
- ✅ 按优先级和阶段分类
- ✅ 添加执行计划和使用建议

---

*最后更新: 2026-01-18 | 版本: v1.0*
