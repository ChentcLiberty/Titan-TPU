# Synthesis Experiments

This directory keeps a tiny-tpu local DC flow for apples-to-apples PPA checks.

Targets:

- `make -f experiments/syn/Makefile baseline_freq`
- `make -f experiments/syn/Makefile pipeline_freq`

Variants:

- `baseline`: current `tpu` top with `src/unified_buffer_v3.sv`
- `pipeline`: `tpu_pipeline` top with the extra `vpu_ub_pipe_stage`

Outputs:

- `experiments/syn/out/baseline/`
- `experiments/syn/out/pipeline/`

Method:

- Reuse the same SMIC 180nm libraries and the same binary-search methodology as `/home/jjt/TitanTPU/syn/dc_freq_search.tcl`.
- Keep the original `/home/jjt/TitanTPU/syn/` directory untouched.

Measured status on 2026-03-25:

- Baseline reference reused from `/home/jjt/TitanTPU/syn/reports/freq_search/qor_final.rpt`:
  - `6.09ns / 164.10MHz`
  - `Cell Area = 850462.184248`
  - `Levels of Logic = 49`
- Local pipeline experiment under `experiments/syn/out/pipeline/`:
  - `qor_iter1_9.0ns.rpt`: PASS, `Cell Area = 773195.536211`, `Levels of Logic = 43`
  - `qor_iter2_6.0ns.rpt`: PASS, `Cell Area = 825237.141466`, `Levels of Logic = 30`
  - `qor_iter3_4.5ns.rpt`: FAIL, `WNS = -0.80`, `Cell Area = 877741.934332`
- Current conservative conclusion:
  - pipeline version is proven to meet `6.00ns / 166.67MHz`
  - exact max frequency can be refined later by continuing the narrowed search between `4.50ns` and `6.00ns`
