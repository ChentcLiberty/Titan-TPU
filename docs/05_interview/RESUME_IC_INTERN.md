# 陈韦东

📞 15155358906 | ✉️ 15155358906@163.com | 🎂 2002-09 | 🏛️ 中共党员 | 📍 成都

---

## 个人优势

有半年及以上实习时间

---

## 教育经历

**电子科技大学** | 硕士 | 光电科学与工程学院 | 电子信息（前10%） | 2024.09 - 2027.06
- 专业课程：处理器设计实验、面向FPGA的数字逻辑设计、半导体器件、模拟集成电路

**合肥师范学院** | 本科 | 电子信息与集成电路学院 | 电子信息（前3%） | 2020.06 - 2024.06
- 奖项证书：国家励志奖学金 | 全国大学生数学竞赛安徽赛区一等奖 | CET6 | 优秀学生一等奖学金 | 优良学风先进个人 | 三好学生 | 新生杯二等奖
- GPA：4.0/5.0

---

## 项目经历

### 一、Titan-TPU V2 — 基于脉动阵列的 AI 加速器设计与验证（个人项目） | 2026.01 - 至今

项目简述：基于开源 tiny-tpu-v2（GitHub 1000+ stars）进行深度定制，实现支持前向推理和反向训练的 Weight Stationary 脉动阵列 TPU。使用 SystemVerilog 完成 RTL 设计，VCS + Verdi 完成功能验证，涵盖 16 个核心模块、Q8.8 定点数算术库和完整训练数据通路。

个人完成：
1. 架构设计：设计 2×2 Weight Stationary Systolic Array，PE 采用双缓冲权重寄存器（active/inactive）实现计算与预加载并行；实现 Unified Buffer 统一存储子系统，支持 7 种读取模式（输入/权重/偏置/Y/H/梯度），含转置和对角线 feed；实现 VPU 向量处理单元，通过 4-bit 数据通路控制信号动态切换前向（Bias→LeakyReLU）和反向（Loss→LeakyReLU导数）计算路径。
2. 功能验证：搭建 VCS + Verdi 专业仿真环境，编写 Makefile 支持单模块测试、回归测试和覆盖率收集（line/cond/fsm/tgl/branch 五维）。使用 Clocking Block 消除 testbench 竞争条件，SVA 断言验证复位和 valid 信号传播。PE 模块 11/11 通过，Systolic Array 5/5 通过，Unified Buffer 3/3 通过。
3. Bug 定位与修复：修复 PE 模块 weight_reg_active 多驱动问题（always_comb + always_ff 统一为纯时序逻辑）；修复 Unified Buffer 读取命令初始化竞争条件（组合逻辑迁移至 always_ff）；修复 Gradient Descent 模块 sub_in_a 多驱动（分离组合/时序逻辑）。

后续计划：集成 ECC SECDED（Hamming 39,32）容错、Sparse PE 零值跳过 + ICG Clock Gating 稀疏优化、AXI4-Lite 总线接口封装。

### 二、基于 Verilog 的 RISC-V CPU 设计与实现（队长） | 2025.03 - 至今

项目简述：设计并实现一个支持 RV32I 指令子集的 5 级流水线 CPU，涵盖指令获取（IF）、指令解码（ID）、执行（EX）、内存访问（MEM）和写回（WB）阶段。项目通过模块化设计实现核心功能，包括控制信号生成、算术逻辑运算、数据冒险处理并通过仿真测试验证功能正确性。

个人完成：
1. 规划 CPU 数据通路与流水线阶段，定义模块接口与交互逻辑。
2. 数据通路设计：基于 MIPS 指令子集完成流水线分阶段设计（取指、译码、执行、访存、写回），优化资源冲突，分离指令存储器（IM）与数据存储器（DM），确保流水线无结构冒险。
3. 数据冒险处理：转发机制，设计旁路逻辑（Forwarding Unit），通过检测 EX/MEM 与 MEM/WB 流水段寄存器的相关性，解决 ALU 结果依赖的 RAW 冒险。阻塞机制：针对 Load-use 冒险，插入硬件阻塞（Stall）并优化流水线控制信号清零逻辑，确保数据一致性。
4. 仿真验证：使用 ModelSim 完成功能仿真，验证 lw、sw、R-type 及分支指令的正确性。

后续计划：扩展中断处理功能，基于 AMBA 总线协议完成外设扩展。

### 三、基于 16×16 路由器（Router）功能验证平台开发 | 2025.03 - 至今

项目简述：设计并实现基于 SystemVerilog 的验证平台，用于验证 16 输入 16 输出路由器的功能正确性、时序一致性及端口仲裁机制。通过覆盖率驱动验证（CDV）方法，完成随机化测试、结果比对及覆盖率收敛，确保设计符合协议规范，支持动态数据包路由及冲突处理。

个人完成：
1. 完成验证环境搭建：构建分层验证架构，包括 Generator（生成随机化数据包）、Driver（驱动 DUT 输入）、Receiver（监测 DUT 输出）、Scoreboard（功能比对与覆盖率统计）。实现端口仲裁机制（Semaphore），解决多驱动端口冲突问题，确保数据包按优先级传输。
2. 开发随机测试用例，覆盖 16 个端口的全路由组合、有效载荷长度（2-4字节）及边界条件。

后续计划：搭建 UVM 验证平台

---

## 知识技能

- 知识：熟悉数模电相关知识，有 FPGA 上板经验，熟悉 Linux 操作系统，了解 APB/AHB/AXI 总线协议，熟悉芯片设计基本知识（代码规范、典型电路如状态机、FIFO），熟悉 AI 加速器脉动阵列架构（Weight Stationary 数据流、定点数运算）
- 语言：熟悉 Verilog/SystemVerilog，了解 UVM 验证方法学，掌握 Clocking Block、SVA 断言、Constrained Random 等验证技术
- 软件：熟悉 VCS、Verdi、Design Compiler，熟悉 Vivado、Quartus、ModelSim、ISE、Gvim
- 脚本：了解 Shell、Tcl、Makefile 构建系统
- 工具：Git 版本控制，覆盖率收集与分析（line/cond/fsm/tgl/branch）

---

## 个人总结

责任感强；具有良好的学习能力，注重工作效率和方法；注重团队协作；具有较强的抗压能力，有效释放压力，注重思考和精进。具备独立定位和修复 RTL Bug 的能力，理解 SystemVerilog 仿真语义（阻塞/非阻塞赋值、竞争条件），有良好的文档习惯和工程化意识。
