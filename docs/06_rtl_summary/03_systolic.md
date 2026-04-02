# 脉动阵列 (systolic.sv)

## 模块定位
2×2 Weight Stationary 脉动阵列，由 4 个 PE 组成，执行矩阵乘法的核心计算引擎。

## 阵列拓扑
```
        W_col1     W_col2
          ↓          ↓
Input1 → PE11  →   PE12
          ↓          ↓
Input2 → PE21  →   PE22
          ↓          ↓
        Out_21     Out_22
```

## PE 互连关系
| 连接 | 说明 |
|------|------|
| PE11.input_out → PE12.input_in | 输入水平传播（行内） |
| PE11.psum_out → PE21.psum_in | 部分和垂直累加（列内） |
| PE12.psum_out → PE22.psum_in | 部分和垂直累加（列内） |
| PE21.input_out → PE22.input_in | 输入水平传播（行内） |
| PE11.weight_out → PE21.weight_in | 权重垂直传播（列内） |
| PE12.weight_out → PE22.weight_in | 权重垂直传播（列内） |

## 信号传播规则
- **Weight accept**：按列独立传播（`sys_accept_w_1` 控制第1列，`sys_accept_w_2` 控制第2列）
- **Switch**：从左上到右下对角传播（PE11 → PE12/PE21 → PE22）
- **Valid/Start**：从 PE11 开始向右、向下传播

## 动态列使能
```systemverilog
pe_enabled <= (1 << ub_rd_col_size_in) - 1;
```
- `ub_rd_col_size_in = 1` → `pe_enabled = 01`（仅第1列）
- `ub_rd_col_size_in = 2` → `pe_enabled = 11`（两列都启用）
- 支持非方阵矩阵乘法，禁用多余列节省功耗

## 输出
- `sys_data_out_21`、`sys_data_out_22`：底部两个 PE 的最终累加结果
- `sys_valid_out_21`、`sys_valid_out_22`：对应有效信号

## 简历话术
> 搭建了 2×2 Weight Stationary 脉动阵列，实现 PE 间水平输入传播和垂直部分和累加。支持动态列使能以处理非方阵矩阵，switch 信号对角传播实现权重双缓冲同步切换。
