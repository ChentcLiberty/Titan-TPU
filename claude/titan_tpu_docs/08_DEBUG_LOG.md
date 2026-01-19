# 08 - Debug 日志

> 记录所有 Debug 过程，包括问题描述、分析、解决方案、学到的教训

---

## 📊 统计总览

| 指标 | 数量 |
|------|------|
| 总问题数 | 1 |
| 已解决 | 0 |
| 进行中 | 1 |
| 平均解决时间 | - |

---

## 🔍 问题列表

### BUG-001: PE 模块多驱动问题

**基本信息**

| 属性 | 值 |
|------|-----|
| 状态 | 🟡 进行中 |
| 优先级 | 🔴 高 |
| 模块 | `_vendor/tiny-tpu-v2/src/pe.sv` |
| 发现日期 | 2025-01-16 |
| 解决日期 | - |

**问题描述**

VCS 编译 pe.sv 时报错：
```
Error-[ICPD] Illegal combination of drivers
  pe.sv, 52-58
  Variable "weight_reg_active" is driven by an invalid combination of 
  procedural drivers.
  
  Variables written on left-hand of "always_comb" cannot be written to by 
  any other process, including other "always" blocks.
```

**复现步骤**
```bash
cd /home/jjt/Titan_TPU_V2/sim/vcs
make pe
# 或者
vcs -full64 -sverilog ../../_vendor/tiny-tpu-v2/src/fixedpoint.sv \
    ../../_vendor/tiny-tpu-v2/src/pe.sv \
    ../../tb/tb_pe.sv
```

**根因分析**

查看 pe.sv 源码：
```systemverilog
// 第 52 行附近 - always_comb 块
always_comb begin
    weight_reg_active = some_condition ? value1 : value2;  // 组合逻辑驱动
end

// 第 58 行附近 - always_ff 块  
always_ff @(posedge clk) begin
    weight_reg_active <= new_value;  // 时序逻辑驱动
end
```

**问题本质**：
- SystemVerilog 规定一个变量只能有一个驱动源
- `always_comb` 和 `always_ff` 同时驱动 `weight_reg_active` 违反规则
- 原作者可能想实现"组合选择 + 寄存器存储"，但写法错误

**解决方案**

方案 A: 统一到 always_ff (推荐)
```systemverilog
// 删除 always_comb 中的赋值
// 修改 always_ff:
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        weight_reg_active <= '0;
    else if (pe_switch_in)
        weight_reg_active <= weight_reg_shadow;  // 从 shadow 切换
    else if (pe_accept_w_in)
        weight_reg_active <= weight_reg_active;  // 保持 (可省略)
end
```

方案 B: 分离组合逻辑
```systemverilog
// 组合逻辑计算下一个值
always_comb begin
    weight_reg_active_next = pe_switch_in ? weight_reg_shadow : weight_reg_active;
end

// 时序逻辑更新寄存器
always_ff @(posedge clk) begin
    weight_reg_active <= weight_reg_active_next;
end
```

**待执行命令**
```bash
# 使用 Claude API 获取修复方案
tpu-env
claude-debug "pe.sv weight_reg_active 被 always_comb(52行) 和 always_ff(58行) 同时驱动" \
    _vendor/tiny-tpu-v2/src/pe.sv

# 修复后验证
make check_pe
make pe
```

**学到的教训**

1. **一信号一驱动**：SystemVerilog 中每个信号只能有一个驱动源
2. **组合/时序分离**：组合逻辑和时序逻辑不要混用
3. **开源代码要审查**：即使是高 star 项目也可能有 Bug
4. **VCS 错误信息有用**：仔细阅读错误信息能快速定位问题

**相关资源**
- SystemVerilog LRM 9.2.2 节：Variable declarations
- VCS User Guide：Error-[ICPD] 说明

---

## 📝 问题模板

复制以下模板记录新问题：

```markdown
### BUG-XXX: [简短标题]

**基本信息**

| 属性 | 值 |
|------|-----|
| 状态 | 🔴 未解决 / 🟡 进行中 / 🟢 已解决 |
| 优先级 | 🔴 高 / 🟡 中 / 🟢 低 |
| 模块 | `文件路径` |
| 发现日期 | YYYY-MM-DD |
| 解决日期 | YYYY-MM-DD |

**问题描述**

[详细描述现象]

**复现步骤**
```bash
[复现命令]
```

**错误信息**
```
[粘贴错误信息]
```

**根因分析**

[分析问题根本原因]

**解决方案**

```systemverilog
// 修复代码
```

**Git Diff**
```diff
- 旧代码
+ 新代码
```

**学到的教训**

1. [教训1]
2. [教训2]

---
```

---

## 🏷️ 常见问题分类

### 编译错误
- [x] BUG-001: 多驱动 (ICPD)

### 仿真错误
- [ ] (暂无)

### 时序问题
- [ ] (暂无)

### 功能错误
- [ ] (暂无)

### 验证环境问题
- [ ] (暂无)

---

## 📚 Debug 技巧积累

### 1. VCS 常见错误

| 错误代码 | 含义 | 常见原因 |
|----------|------|----------|
| ICPD | Illegal combination of drivers | 多驱动 |
| IWNF | Implicit wire has no fanout | 未连接信号 |
| CAWM | Continuous assignment width mismatch | 位宽不匹配 |
| UII | Undefined identifier | 未声明变量 |

### 2. 波形调试技巧

```
1. 找到出错时刻
2. 追踪相关信号
3. 检查输入是否正确
4. 检查状态机状态
5. 对比 Golden Model
```

### 3. 分而治之

```
1. 先验证最小单元 (PE)
2. 再验证子系统 (Systolic Array)
3. 最后验证顶层 (TPU)
4. 问题定位到哪一层
```

---

## 🔗 相关文档

- [03_TECHNICAL_REFERENCE.md](./03_TECHNICAL_REFERENCE.md) - 技术规格
- [07_PROGRESS_TRACKER.md](./07_PROGRESS_TRACKER.md) - 进度追踪
- [06_AI_TOOLS_GUIDE.md](./06_AI_TOOLS_GUIDE.md) - AI 工具使用

---

*文档版本: v1.0 | 更新时间: 2025-01-16*
