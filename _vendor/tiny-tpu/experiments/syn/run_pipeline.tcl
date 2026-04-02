set DESIGN_NAME "tpu_pipeline"
set SYSTOLIC_WIDTH 2
set FILELIST "/home/jjt/TitanTPU/_vendor/tiny-tpu/experiments/syn/filelist_pipeline.f"
set OUT_DIR "/home/jjt/TitanTPU/_vendor/tiny-tpu/experiments/syn/out/pipeline"

set MIN_PERIOD 3.0
set MAX_PERIOD 15.0
set TOLERANCE 0.1
set MAX_AREA 800000

source /home/jjt/TitanTPU/_vendor/tiny-tpu/experiments/syn/dc_freq_search_generic.tcl
