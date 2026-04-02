# tiny-tpu Repo Cleanup Plan (2026-04-02)

## 0. 当前结论

当前这条主线已经可以定性为：

- 功能 debug 已完成
- AXI e2e: `41/41 PASS`
- repeated-start 多 epoch 收敛验证已完成
  - 12 epoch: 通过
  - 50 epoch stress check: 通过
- 训练流当前可以稳定支持 epoch

因此，后续工作重点已经从功能修复切换为源码树整理与纳管边界。

## 1. 已完成的纳管批次

### 1.1 AXI / 训练主线源码

本轮已纳管并推远端：

- `_vendor/tiny-tpu/src_axi/` 关键源码
- `_vendor/tiny-tpu/compiler/ub_allocator.py`
- `_vendor/tiny-tpu/compiler/model_specs/mlp_2_2_1_q8_8.json`
- `_vendor/tiny-tpu/test/dump_tpu_soc.sv`
- `_vendor/tiny-tpu/test/test_tpu_soc_axil_train_convergence.py`

### 1.2 实验 / 变体 / bench 配套

已纳管并推远端：

- `_vendor/tiny-tpu/experiments/`
- `_vendor/tiny-tpu/src/pipeline_exp/`
- `_vendor/tiny-tpu/src/handshake_exp/`
- `_vendor/tiny-tpu/src_axi/pipeline_exp/`
- `_vendor/tiny-tpu/test/tb_tpu_soc_axil.sv`
- `_vendor/tiny-tpu/test/dump_tpu_pipeline.sv`
- `_vendor/tiny-tpu/test/dump_tpu_handshake.sv`
- `_vendor/tiny-tpu/test/dump_vpu_ub_skid_stage.sv`
- `_vendor/tiny-tpu/test/test_vpu_ub_skid_stage.py`
- `_vendor/tiny-tpu/compiler/README.md`
- `_vendor/tiny-tpu/compiler/out/mlp_2_2_1_q8_8.ub_map.json`

### 1.3 根目录综合支撑

建议并已纳管：

- `syn/Makefile`
- `syn/README.md`
- `syn/constraints.sdc`
- `syn/dc_script.tcl`
- `syn/dc_freq_search.tcl`
- `syn/filelist.f`

同时，以下明显属于生成产物的目录或文件模式应保持 ignore：

- `sim/waveforms/`
- `syn/*.mr`
- `syn/*-verilog.pvl`
- `syn/*-verilog.syn`
- `syn/default.svf`
- `syn/alib-52/`
- `syn/logs/`
- `syn/outputs/`
- `syn/reports/`

## 2. 当前仍然剩余的脏内容

### 2.1 已跟踪但非本轮功能修复的旧改动

这些内容不是当前收敛修复的一部分，建议后续拆分成独立任务：

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
- `sim/vcs/verdi_init.tcl`（已删除待确认）
- `sim/vcs/verdi_large_font.sh`（已删除待确认）
- `tb/tb_pe.sv`

### 2.2 尚未纳管的探索/资料目录

这些内容目前不影响主功能，但是否进入主线还需要单独判断：

- `_vendor/tiny-tpu/debug/`
- `_vendor/tiny-tpu/rtl_nxn_refactor/`
- `_vendor/tiny-tpu/src_axi/handshake_exp/`
- `_vendor/tiny-tpu/src/unified_buffer_v2_simple.sv`
- `_vendor/tiny-tpu/src_axi/unified_buffer*.sv` 的历史变体
- `_vendor/tiny-tpu/test/test_bias_parent_verification.py`
- `_vendor/tiny-tpu/test/test_loss_parent_verification.py`
- `_vendor/tiny-tpu/test/test_leaky_relu_parent_verification.py`
- `_vendor/tiny-tpu/test/test_leaky_relu_derivative_parent_verification.py`
- `_vendor/tiny-tpu/test/test_systolic_boundary.py`
- `_vendor/tiny-tpu/test/test_vpu_verification.py`
- `docs/05_interview/`、`docs/06_rtl_summary/` 等面试/总结资料

## 3. 关于 epoch 与收敛的最终口径

现在可以稳妥地说：

> 当前 2-2-1 XOR、Q8.8、AXI SoC 路径下，已经完成 repeated-start 多 epoch 训练验证。
> 12 epoch 可收敛到正确 XOR 分类，50 epoch stress check 也验证了训练稳定性。

仍然不要升级成：

> 任意网络、任意数据集、任意超参数都完成了完整训练验证。

## 4. 下一步最合理的整理顺序

1. 单独处理 `_vendor/tiny-tpu/src/` 里那批旧 tracked 修改，判断哪些该保留、哪些只是历史试验。
2. 再决定 `_vendor/tiny-tpu/debug/` 和 `docs/05_interview/` 这类资料是放主仓库、迁 `archive/`，还是只留共享目录。
3. `rtl_nxn_refactor/` 与 `src_axi/handshake_exp/` 继续单独开任务，不和主线功能混提。

## 5. 一句话结论

- 功能：稳定，debug 已完成
- 收敛：已验证，可做 epoch
- 当前剩余问题：仓库结构和历史遗留内容整理
