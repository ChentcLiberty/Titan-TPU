# 偏置加法模块 (bias_child.sv / bias_parent.sv)

## 模块定位
VPU 第一级处理，对 Systolic Array 输出的矩阵乘法结果加上偏置标量，完成 Z = WX + b。

## 层次关系
```
bias_parent（顶层，2路并行）
  ├── bias_child column_1（第1列）
  └── bias_child column_2（第2列）
```

## bias_child 内部结构
```
bias_sys_data_in (来自Systolic) ──→ [fxp_add] ──→ z_pre_activation ──→ [寄存器] ──→ bias_z_data_out
bias_scalar_in (来自UB)         ──→ [fxp_add]
```

## 工作原理
- 每个 child 处理一列特征，对应一个偏置标量
- `fxp_add`：Q8.8 定点加法，组合逻辑
- 输出寄存一拍（`always @(posedge clk)`），引入 1 cycle 延迟
- `bias_sys_valid_in` 控制有效数据通过，无效时输出清零

## bias_parent 角色
- 纯结构化封装，实例化 2 个 bias_child
- 将 2 路偏置标量分别连接到对应列
- 无额外逻辑

## 接口
| 信号 | 说明 |
|------|------|
| bias_sys_data_in [15:0] | Systolic 输出（WX 的一个元素） |
| bias_scalar_in [15:0] | 偏置标量（从 UB 读取） |
| bias_z_data_out [15:0] | 预激活值 Z = WX + b |
| bias_Z_valid_out | 输出有效信号 |

## 简历话术
> 实现了偏置加法模块，采用 parent-child 层次化设计，每列独立处理一个偏置标量，Q8.8 定点加法后寄存输出，1 cycle 延迟。
