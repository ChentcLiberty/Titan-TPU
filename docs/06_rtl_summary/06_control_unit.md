# 控制单元 (control_unit.sv)

## 模块定位
指令译码器，将 88-bit 指令字解码为 TPU 各子系统的控制信号，纯组合逻辑实现。

## 指令格式（88-bit，低位到高位）
```
[0]      sys_switch_in           - 权重双缓冲切换
[1]      ub_rd_start_in          - UB 读取启动
[2]      ub_rd_transpose         - 转置读取使能
[3]      ub_wr_host_valid_in_1   - Host 写入通道1有效
[4]      ub_wr_host_valid_in_2   - Host 写入通道2有效
[6:5]    ub_rd_col_size          - 矩阵列数
[14:7]   ub_rd_row_size          - 矩阵行数
[16:15]  ub_rd_addr_in           - UB 读取地址
[19:17]  ub_ptr_sel              - 读取模式选择（0-6）
[35:20]  ub_wr_host_data_in_1    - Host 写入数据通道1
[51:36]  ub_wr_host_data_in_2    - Host 写入数据通道2
[55:52]  vpu_data_pathway        - VPU 通路控制
[71:56]  inv_batch_size_times_two - 2/N（MSE 损失系数）
[87:72]  vpu_leak_factor_in      - LeakyReLU 泄漏因子
```

## 设计特点
- 纯 `assign` 连续赋值，零延迟组合逻辑
- 无状态机，无时序逻辑，仅做位域切片
- 单周期译码，不引入流水线气泡

## 简历话术
> 实现了 88-bit 指令译码控制单元，通过位域切片将指令字解码为 UB 读写控制、Systolic 权重切换、VPU 通路选择等信号，纯组合逻辑零延迟译码。
