# Experiments

这个目录统一收口面试准备阶段新增的可执行实验入口、VCS testbench、日志和波形。

当前目标：

- `pipeline_unit`：验证 `VPU -> UB` 插入一级寄存器后，输出整体晚一拍。
- `handshake_unit`：验证标准 ready/valid 语义下的局部 skid stage，第一拍 miss 的数据会被 hold，等待中的下一拍可以稳定停在输入口，只有 blocked input 被改写时才报 `overflow`。
- `handshake_random_unit`：用随机 `ready` 抖动和周期性 forced-low 构造 backpressure，验证 held payload 不丢失、`holding_out`/`stall_cycles` 真实出现、`overflow_out` 不误报。
- `overflow_unit`：验证 Q8.8 在超范围乘法/加法时会饱和，而不是简单回绕。

配套源码位置：

- `src/pipeline_exp/`
- `src/handshake_exp/`
- `debug/`

使用方式：

- `make -f experiments/Makefile pipeline_unit`
- `make -f experiments/Makefile handshake_unit`
- `make -f experiments/Makefile handshake_random_unit`
- `make -f experiments/Makefile overflow_unit`

产物位置：

- 日志：`experiments/out/logs/`
- 可执行文件：`experiments/out/build/`
- 波形：`experiments/out/waves/`

2026-03-26 当前状态：

- `pipeline_unit`：PASS
- `handshake_unit`：PASS
- `handshake_random_unit`：PASS
- `overflow_unit`：PASS
- 当前四份 FSDB：
  - `experiments/out/waves/pipeline_unit.fsdb`
  - `experiments/out/waves/handshake_unit.fsdb`
  - `experiments/out/waves/handshake_random_unit.fsdb`
  - `experiments/out/waves/overflow_unit.fsdb`
- 随机反压摘要：`experiments/out/logs/handshake_random_summary.txt`

如果要用 Verdi 看波形，优先打开对应 `*.fsdb`。
