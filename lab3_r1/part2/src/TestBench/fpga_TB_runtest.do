SetActiveLib -work
comp -include "$dsn\src\MIPS_package.vhd" 
comp -include "$dsn\src\REG.vhd" 
comp -include "$dsn\src\memory.vhd" 
comp -include "$dsn\src\MIPS.vhd" 
comp -include "$dsn\src\hexToSevenSegmentDecoder.vhd" 
comp -include "$dsn\src\fpga.vhd" 
comp -include "$dsn\src\TestBench\fpga_TB.vhd" 
asim +access +r TESTBENCH_FOR_fpga 
wave 
wave -noreg CLOCK_50
wave -noreg CLOCK2_50
wave -noreg CLOCK3_50
wave -noreg CLOCK4_50
wave -noreg SW
wave -noreg KEY
wave -noreg LEDR
wave -noreg HEX0
wave -noreg HEX1
wave -noreg HEX2
wave -noreg HEX3
wave -noreg HEX4
wave -noreg HEX5
# The following lines can be used for timing simulation
# acom <backannotated_vhdl_file_name>
# comp -include "$dsn\src\TestBench\fpga_TB_tim_cfg.vhd" 
# asim +access +r TIMING_FOR_fpga 
