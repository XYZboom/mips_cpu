-makelib xcelium_lib/xil_defaultlib -sv \
  "F:/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "F:/Xilinx/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/blk_mem_gen_v8_4_2 \
  "../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../design1.srcs/sources_1/ip/rom_1024x32b/sim/rom_1024x32b.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib
