# tiny-tpu Worktree Audit (2026-04-02)

## 1. 本轮 debug 结论

本轮针对 AXI SoC 路径下的多 epoch XOR 训练收敛问题，已经在以下两个位置完成验证：

- `/home/jjt/tpu-soc`
- `/home/jjt/TitanTPU/_vendor/tiny-tpu`

当前确认通过的回归：

- `make test_tpu_soc_axil_e2e`
  - 结果：`41/41 PASS`
- `test_tpu_soc_axil_train_convergence.py`（一次性命令跑）
  - 结果：12 epoch 收敛到 `pred=(0,1,1,0)`
  - loss：`0.2432 -> 0.1777`

因此，**本轮训练收敛主 bug 已经 debug 完成**。

## 2. 本轮真正相关并已同步的文件

这些文件属于“收敛修复 + repeated-start + non-zero LR + IMEM 调度一致化”这一组：

- `src/unified_buffer_v3.sv`
- `src_axi/unified_buffer_v3.sv`
- `src_axi/tpu_frontend_axil.sv`
- `src_axi/tpu_soc.sv`
- `src_axi/tpu.sv`
- `compiler/scheduler.py`
- `compiler/out/imem.hex`
- `compiler/out/imem.txt`
- `compiler/out/mlp_2_2_1_q8_8.schedule.json`
- `test/test_tpu_soc_axil_train_convergence.py`

其中本轮最终直接收掉收敛 blocker 的关键修复是：

- `src/unified_buffer_v3.sv`
- `src_axi/unified_buffer_v3.sv`

核心原因：weight-mode 的 `grad_descent_valid_in` 提前一拍关闭，导致 `W2[1]` 和 `W1[*][1]` 的最后一拍更新被丢。

## 3. 本轮为防覆盖所做的备份

### 原仓库备份

- `src/unified_buffer_v3.sv.bak_20260402_convergence_sync`
- `src_axi/unified_buffer_v3.sv.bak_20260402_convergence_sync`
- `src_axi/tpu_frontend_axil.sv.bak_20260402_convergence_sync`
- `src_axi/tpu_soc.sv.bak_20260402_convergence_sync`
- `src_axi/tpu.sv.bak_20260402_convergence_sync`
- `compiler/scheduler.py.bak_20260402_convergence_sync`
- `compiler/out/imem.hex.bak_20260402_convergence_sync`
- `compiler/out/imem.txt.bak_20260402_convergence_sync`
- `compiler/out/mlp_2_2_1_q8_8.schedule.json.bak_20260402_convergence_sync`

### /home/jjt/tpu-soc 内调试备份

- `src_axi/unified_buffer_v3.sv.bak_20260402_weightvalid`
- `src/unified_buffer_v3.sv.bak_20260402_weightvalid`
- 更早的 `biaswin / wrptr / weightprobe` 备份也仍然保留

## 4. 当前 worktree 中“不是这轮修复”的脏改动

以下内容在当前 `git status` 中存在，但**不属于这次收敛修复**，本轮没有去改，也没有清理：

### 已跟踪但与本轮收敛修复无关的修改

- `Makefile`
- `src/pe.sv`
- `src/tpu.sv`
- `src/vpu.sv`
- `test/dump_tpu.sv`
- `test/test_pe.py`
- `waveforms/tpu.gtkw`
- `waveforms/vpu.gtkw`
- `../../docs/04_progress/AXI_SOC_FULL_SUMMARY.md`
- `../../sim/vcs/Makefile`
- `../../tb/tb_pe.sv`
- 以及 `../../sim/vcs/` 下的删除项

### 大量未跟踪的综合/仿真/实验产物

典型包括：

- `*.mr`
- `*-verilog.pvl`
- `*-verilog.syn`
- `alib-52/`
- `tiny-tpu-200m/`
- `sim_build_vcs/`
- `waveforms/` 下运行产物
- `pipeline_exp/`、`handshake_exp/`、`rtl_nxn_refactor/` 等实验目录
- `src_axi/` 下一部分尚未纳入 git 跟踪的文件

这些内容当前**仍然混在 worktree 里**，但它们不是本轮收敛 bug 的 blocker。

## 5. 为什么本轮没有直接“清空 worktree”

原因很明确：

- 里面有明显不是自动生成、很可能是你已有工作的内容
- 也有大量历史综合/仿真产物
- 还有一部分 AXI 路径文件目前在原仓库里本身就处于“部分 tracked、部分 untracked”的混合状态

在这种前提下，直接 `clean/reset` 风险很高，会误删你的内容，所以本轮只做了：

- 分类
- 备份
- 只同步这次 debug 真正相关的小集合文件
- 不碰其余脏改动

## 6. 当前最合理的后续整理顺序

建议单独做一次“worktree 清理/纳管”任务，和功能 debug 分开：

1. 先把 AXI SoC 真正需要长期保留的文件集合列出来
2. 再决定哪些 `src_axi/` 文件应该正式纳入 git
3. 再把综合/仿真产物移出源码树或补 `.gitignore`
4. 最后单独做一次“结构整理 commit”

不要把这件事和功能 bug 修复混在一个 commit 里。

## 7. 当前一句话结论

- **功能 debug：已经完成**
- **原仓库 worktree：仍然很脏，但本轮已经完成分类和保护性同步，未做破坏性清理**
