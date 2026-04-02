# 陈韦东

📞 15155358906 | ✉️ 15155358906@163.com | 🎂 2002-09 | 🏛️ 中共党员 | 📍 成都

---

## 个人优势

- 有半年及以上实习时间，可全职实习
- 具备完整的 RTL 设计到综合验证全流程经验
- 熟悉 AI 加速器架构设计与验证方法学

---

## 教育经历

**电子科技大学** | 硕士 | 光电科学与工程学院 | 电子信息（前10%） | 2024.09 - 2027.06
- 专业课程：处理器设计实验、面向FPGA的数字逻辑设计、半导体器件、模拟集成电路

**合肥师范学院** | 本科 | 电子信息与集成电路学院 | 电子信息（前3%） | 2020.06 - 2024.06
- 奖项证书：国家励志奖学金 | 全国大学生数学竞赛安徽赛区一等奖 | CET6 | 优秀学生一等奖学金 | 优良学风先进个人 | 三好学生
- GPA：4.0/5.0

---

## 项目经历

### 一、Titan-TPU V2 — MLP脉动阵列加速器 RTL 设计与验证（个人项目） | 2025.09 - 至今

**项目简述**：基于 tiny-tpu 深度定制 2×2 Weight Stationary 脉动阵列 TPU，扩展前向推理、反向传播和权重更新数据通路，并完成 AXI-Lite SoC 封装、端到端验证与综合优化。使用 SystemVerilog / cocotb / Python / VCS / Verdi / Synopsys DC 完成 RTL、验证、调试、综合闭环。

**个人完成**：
1. **微架构与数据流设计**：完成 TPU 原型底层 RTL 构建。采用 Weight Stationary 数据流，实现 2×2 脉动阵列 MAC 数据通路、部分和累加及 valid 级联；完成 Unified Buffer 读写位宽匹配，支持 Host 双通道写入、事务式读出及转置供数。
2. **算子映射与控制流**：实现 VPU 与后处理控制逻辑，完成 Bias、Leaky ReLU、MSE Loss、Gradient Descent 等算子链的 RTL 映射；通过控制字段译码与流水线对齐，打通 forward / backward 完整数据通路。
3. **SoC 集成与指令架构**：设计并实现 AXI-Lite SoC 封装层，定义 32-bit IMEM 指令格式（opcode / addr / ptr_sel / vpu_pathway / wait_after）；实现 4 状态 sequencer FSM（IDLE / DISPATCH / WAIT / ADVANCE），支持 `vpu_drain` 握手和显式 `wait_after` 标记；配套编写 Python 调度器与指令编码器，自动生成 59 条 MLP 指令，覆盖 forward / backward / weight update。
4. **综合与 PPA 优化**：基于 SMIC 180nm `tt_1v8_25c` 编写综合/扫频脚本与 SDC 约束。定位 VPU→UB 45 级组合逻辑关键路径，通过插入流水线寄存器并继续细扫时钟周期，使频率由 `164.10 MHz` 逐步提升到 `183.91 MHz`（中间已证明频点 `166.67 MHz`），逻辑深度最终归纳到约 38 级，DRC 0 违例；识别 UB register file 面积热点，通过 buffer 深度 `128→32` 与 operand isolation 优化，总面积由 839K 降至 454K μm²（-46%），动态功耗下降 2.73 mW（-9.4%）。
5. **验证与系统调试**：基于 cocotb + NumPy 搭建自动化验证平台，提取 2-2-1 XOR 训练权重，建立 16-bit Q8.8 定点参考模型进行端到端比对；定位并修复 6 类系统级 bug，涵盖 Icarus unpacked array/X 传播、IMEM 指令字段缺失、sequencer drain 时序错误、权重 shadow load 建立时间不足等问题；最终 AXI SoC e2e 测试 H1 输出达到 6/8 PASS，与原始 testbench 完全一致，并确认 2 个 FAIL 来自原 RTL 的 bias 对齐遗留 bug。

**技术栈**：SystemVerilog | cocotb | Python | NumPy | VCS + Verdi | Synopsys DC | SMIC 180nm PDK | Makefile | Git

---

### 二、基于 Verilog 的 RISC-V CPU 设计与实现（队长） | 2025.03 - 至今

**项目简述**：设计并实现支持 RV32I 指令子集的 5 级流水线 CPU，涵盖取指（IF）、译码（ID）、执行（EX）、访存（MEM）、写回（WB）阶段。通过模块化设计实现核心功能，包括控制信号生成、ALU 运算、数据冒险处理，并通过 ModelSim 仿真验证功能正确性。

**个人完成**：
1. **数据通路设计**：基于 MIPS 指令子集完成流水线分阶段设计，分离指令存储器（IM）与数据存储器（DM），优化资源冲突，确保流水线无结构冒险。
2. **数据冒险处理**：
   - **转发机制**：设计旁路逻辑（Forwarding Unit），通过检测 EX/MEM 与 MEM/WB 流水段寄存器的相关性，解决 ALU 结果依赖的 RAW 冒险。
   - **阻塞机制**：针对 Load-use 冒险，插入硬件阻塞（Stall）并优化流水线控制信号清零逻辑，确保数据一致性。
3. **仿真验证**：使用 ModelSim 完成功能仿真，验证 lw、sw、R-type 及分支指令的正确性。

**后续计划**：扩展中断处理功能，基于 AMBA 总线协议完成外设扩展。

---

### 三、基于 16×16 路由器（Router）功能验证平台开发 | 2025.03 - 至今

**项目简述**：设计并实现基于 SystemVerilog 的验证平台，用于验证 16 输入 16 输出路由器的功能正确性、时序一致性及端口仲裁机制。通过覆盖率驱动验证（CDV）方法，完成随机化测试、结果比对及覆盖率收敛，确保设计符合协议规范。

**个人完成**：
1. **验证环境搭建**：构建分层验证架构，包括 Generator（生成随机化数据包）、Driver（驱动 DUT 输入）、Receiver（监测 DUT 输出）、Scoreboard（功能比对与覆盖率统计）。实现端口仲裁机制（Semaphore），解决多驱动端口冲突问题，确保数据包按优先级传输。
2. **随机测试用例开发**：覆盖 16 个端口的全路由组合、有效载荷长度（2-4字节）及边界条件。

**后续计划**：搭建 UVM 验证平台。

---

## 知识技能

- **知识**：熟悉数模电相关知识，有 FPGA 上板经验，熟悉 Linux 操作系统，了解 APB/AHB/AXI/AXI-Lite 总线协议，熟悉芯片设计基本知识（代码规范、典型电路如状态机、FIFO），熟悉 AI 加速器脉动阵列架构（Weight Stationary 数据流、定点数运算）
- **语言**：熟悉 Verilog/SystemVerilog，了解 UVM 验证方法学，掌握 Clocking Block、SVA 断言、Constrained Random 等验证技术
- **软件**：熟悉 VCS、Verdi、Design Compiler，熟悉 Vivado、Quartus、ModelSim、ISE、Gvim
- **脚本**：了解 Shell、Tcl、Makefile 构建系统，熟悉 Python（cocotb 验证、NumPy 参考模型、指令调度/编码脚本）
- **工具**：Git 版本控制，覆盖率收集与分析（line/cond/fsm/tgl/branch）

---

## 个人总结

责任感强，具有良好的学习能力和团队协作精神。具备独立定位和修复 RTL Bug 的能力，理解 SystemVerilog 仿真语义（阻塞/非阻塞赋值、竞争条件），熟悉验证方法学（Reference Model、Scoreboard、Coverage），有良好的文档习惯和工程化意识。注重工作效率和方法，具有较强的抗压能力。
