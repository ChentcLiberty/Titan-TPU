# DC Synthesis for tiny-tpu

## 目录结构
```
syn/
├── Makefile           # 综合自动化脚本
├── dc_script.tcl      # DC 综合主脚本
├── constraints.sdc    # 时序约束文件
├── filelist.f         # RTL 文件列表
├── reports/           # 综合报告（自动生成）
├── outputs/           # 综合输出网表（自动生成）
└── logs/              # 综合日志（自动生成）
```

## 使用前准备

### 1. 配置工艺库
编辑 `dc_script.tcl`，修改以下内容：

```tcl
# 设置工艺库路径
set target_library "your_target.db"
set link_library "* your_target.db"
```

替换为你实际使用的工艺库，例如：
```tcl
set target_library "typical_1v8_25c.db"
set link_library "* typical_1v8_25c.db"
```

### 2. 设置目标频率
编辑 `constraints.sdc`，修改时钟周期：

```tcl
set CLK_PERIOD 10.0  # 10ns = 100MHz
```

## 运行综合

### 基本综合
```bash
cd syn
make syn
```

### 频率扫描（自动测试最高频率）
```bash
make sweep_freq
```
这会自动测试多个频率点：50MHz, 66MHz, 100MHz, 125MHz, 166MHz, 200MHz, 250MHz, 333MHz, 500MHz

### 查看报告
```bash
make view_timing  # 查看时序报告
make view_area    # 查看面积报告
make view_qor     # 查看 QoR 总结
```

### 清理
```bash
make clean
```

## 报告解读

### 时序报告 (reports/timing.rpt)
- **Slack**: 时序余量
  - 正值：满足时序
  - 负值：违反时序
- **Critical Path**: 关键路径延迟

### 面积报告 (reports/area.rpt)
- **Total cell area**: 总单元面积
- **Combinational area**: 组合逻辑面积
- **Sequential area**: 时序逻辑面积

### QoR 报告 (reports/qor.rpt)
- 综合质量总结
- 包含时序、面积、功耗的总体信息

## 优化建议

### 如果时序不满足：
1. 降低目标频率（增大 CLK_PERIOD）
2. 添加流水线寄存器
3. 优化关键路径逻辑
4. 使用 `compile_ultra` 的高级选项

### 如果面积过大：
1. 使用 `set_max_area` 约束
2. 检查是否有不必要的资源
3. 优化数据位宽

### 如果功耗过高：
1. 启用时钟门控（已在脚本中启用）
2. 降低工作频率
3. 优化翻转率高的信号

## 常见问题

### Q: dc_shell 找不到
A: 确保 Synopsys DC 已正确安装并添加到 PATH

### Q: 工艺库找不到
A: 检查 dc_script.tcl 中的库路径设置

### Q: 综合时间过长
A: 可以先用 `compile` 代替 `compile_ultra` 进行快速测试

## 下一步

综合完成后，可以：
1. 使用 PrimeTime 进行静态时序分析（STA）
2. 使用 ICC/ICC2 进行布局布线（P&R）
3. 进行门级仿真验证
