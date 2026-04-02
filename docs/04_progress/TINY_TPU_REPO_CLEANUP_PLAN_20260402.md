# tiny-tpu Repo Cleanup Plan (2026-04-02)

## 1. 当前功能状态

功能上已经不需要继续 debug：

- AXI e2e: `41/41 PASS`
- 多 epoch 收敛验证：
  - 12 epoch: 通过
  - 50 epoch stress check: 通过
  - repeated-start 稳定
  - `wr_ptr` 不漂移

因此，后续工作重点不再是功能修复，而是源码树整理和纳管边界。

## 2. 建议分类

### A. 应该正式纳管的内容

这些内容是“真实源码 / 真实测试 / 真实工具”，应该逐步纳入版本控制，而不是继续散落在 worktree 里。

#### 2.1 已纳管核心 AXI/训练流

本轮已经纳管：

- `_vendor/tiny-tpu/src_axi/`
  - 这批是 AXI SoC 路径真正依赖的源码
- `_vendor/tiny-tpu/compiler/ub_allocator.py`
- `_vendor/tiny-tpu/compiler/model_specs/mlp_2_2_1_q8_8.json`
- `_vendor/tiny-tpu/test/dump_tpu_soc.sv`
- `_vendor/tiny-tpu/test/test_tpu_soc_axil_train_convergence.py`

#### 2.2 建议下一批纳管

这些文件/目录看起来是有工程价值的，而不是纯产物：

- `_vendor/tiny-tpu/compiler/README.md`
  - 应作为 compiler 用法说明保留
- `_vendor/tiny-tpu/compiler/out/mlp_2_2_1_q8_8.ub_map.json`
  - 如果它是“当前 AXI/IMEM/UB 分配的规范输出”，建议纳管
- `_vendor/tiny-tpu/experiments/`
  - 里面有明确的 README、Makefile、syn TCL、实验 bench
  - 这更像“实验基础设施”，不是垃圾文件
- `_vendor/tiny-tpu/src_axi/pipeline_exp/`
  - 包含 `tpu_pipeline.sv` 和 `vpu_ub_pipe_stage.sv`
  - 如果你的简历和文档继续引用时序优化，这部分建议纳管
- `_vendor/tiny-tpu/test/tb_tpu_soc_axil.sv`
  - AXI SoC bench 支撑文件，建议纳管
- `_vendor/tiny-tpu/test/test_vpu_verification.py`
- `_vendor/tiny-tpu/test/test_systolic_boundary.py`
- `_vendor/tiny-tpu/test/test_bias_parent_verification.py`
- `_vendor/tiny-tpu/test/test_loss_parent_verification.py`
- `_vendor/tiny-tpu/test/test_leaky_relu_parent_verification.py`
- `_vendor/tiny-tpu/test/test_leaky_relu_derivative_parent_verification.py`
  - 如果这些验证真的是你现在在维护的验证体系的一部分，也建议纳管

### B. 建议忽略或迁出的内容

这些内容更像临时产物、历史备份、导出结果、工具中间文件，不建议继续留在源码树里参与日常状态判断。

#### 3.1 应长期 ignore 的产物类

- `*.mr`
- `*-verilog.pvl`
- `*-verilog.syn`
- `alib-52/`
- `tiny-tpu-200m/`
- `tiny-tpu-instruction/`
- `sim_build_vcs/`
- `vfastLog/`
- `waveforms/*.fst`
- `waveforms/vcd2fsdbLog/`
- `compiler/__pycache__/`
- `*.bak`
- `*.bak_*`

这部分本轮已经加了一轮 `.gitignore`，后续不建议再把这些产物纳入 git。

#### 3.2 建议迁出源码树的个人/阶段性导出物

- `resume_test.pdf`
- `resume_test.png`
- 面试/简历相关的大部分生成物
- 一次性截图、临时说明图

这些内容建议放到 `docs/`、`archive/` 或共享盘，而不是主仓库功能树里。

### C. 暂缓处理的内容

这些内容不是明显垃圾，也不一定该立即纳管，建议你后面单独开任务判断。

#### 4.1 `rtl_nxn_refactor/`

从结构上看，它更像一个独立重构尝试，里面甚至带 `backup_original_src/`。

判断建议：

- 如果你后面真的还要继续做 `NxN` 参数化重构：
  - 建议单独成分支/子目录并补 README
- 如果只是阶段性尝试：
  - 建议迁到 `archive/`，不要长期挂在主 worktree

当前不建议直接纳管进主线。

#### 4.2 `src/handshake_exp/` / `src_axi/handshake_exp/`

这类目录像功能探索，不一定是主线必要内容。

判断建议：

- 如果后面会继续做 handshake/CDC/elastic buffer：保留并加 README
- 否则迁到 `experiments/`

#### 4.3 `Makefile.handshake_exp` / `Makefile.pipeline_exp`

这类文件说明实验逻辑本来就不属于主 Makefile。

判断建议：

- 若保留实验：迁入 `experiments/`
- 若不再用：移到 `archive/`

## 3. 剩余 tracked 但非本轮功能修复的旧改动

这些不是这次收敛修复的一部分，建议不要和 AXI convergence commit 混在一起：

- `_vendor/tiny-tpu/Makefile`
- `_vendor/tiny-tpu/src/pe.sv`
- `_vendor/tiny-tpu/src/tpu.sv`
- `_vendor/tiny-tpu/src/vpu.sv`
- `_vendor/tiny-tpu/test/dump_tpu.sv`
- `_vendor/tiny-tpu/test/test_pe.py`
- `_vendor/tiny-tpu/waveforms/tpu.gtkw`
- `_vendor/tiny-tpu/waveforms/vpu.gtkw`
- `docs/04_progress/AXI_SOC_FULL_SUMMARY.md`
- `sim/vcs/Makefile`
- `tb/tb_pe.sv`

建议单独再拆成两类：

- 真实源码/验证改动
- 纯环境/波形/文档改动

然后分别提交，不要混在一起。

## 4. 最推荐的后续整理顺序

### 第一步：补齐“应该纳管”的实验基础设施

建议下一批单独 commit：

- `_vendor/tiny-tpu/experiments/`
- `_vendor/tiny-tpu/src_axi/pipeline_exp/`
- `_vendor/tiny-tpu/test/tb_tpu_soc_axil.sv`
- `_vendor/tiny-tpu/compiler/README.md`
- `_vendor/tiny-tpu/compiler/out/mlp_2_2_1_q8_8.ub_map.json`（若确认是规范输出）

### 第二步：把探索性目录移出主线或补 README

重点处理：

- `_vendor/tiny-tpu/rtl_nxn_refactor/`
- `_vendor/tiny-tpu/src/handshake_exp/`
- `_vendor/tiny-tpu/src_axi/handshake_exp/`
- `Makefile.handshake_exp`
- `Makefile.pipeline_exp`

### 第三步：单独处理旧 tracked 改动

特别是：

- `src/pe.sv`
- `src/tpu.sv`
- `src/vpu.sv`
- `Makefile`

这些如果你确认仍然有价值，就拆成一个单独 commit；如果是过时试验，再决定回收方式。

## 5. 关于“算法现在能不能做 epoch” 的最终口径

现在可以稳妥地说：

> 当前 2-2-1 XOR、Q8.8、AXI SoC 路径下，已经完成 repeated-start 多 epoch 训练验证。
> 12 epoch 可收敛到正确 XOR 分类，50 epoch stress check 也验证了训练稳定性。

但不要升级成：

> 任意网络、任意数据集、任意超参数都完成了完整训练验证。

## 6. 一句话结论

- 功能：已经稳定
- epoch：已经验证，且 50 epoch 也通过
- 当前剩余问题：不是功能，而是仓库结构整理
