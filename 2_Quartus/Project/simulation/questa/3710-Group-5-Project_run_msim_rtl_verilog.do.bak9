transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/branch_TOP.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/data_path.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/decoder.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/hex7seg.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/instr_buffer.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/MUXs.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/pc.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/regfile.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/util {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/util/clock_div.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/bram.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/branch_FSM.v}
vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5 {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/alu.v}

vlog  -work work +incdir+C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/LAB4b-tbs {C:/Users/mmess/OneDrive/Documents/GitHub/3710-Group-5/LAB4b-tbs/load_store_TB.v}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L cyclonev_ver -L cyclonev_hssi_ver -L cyclonev_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  load_store_TB

add wave *
view structure
view signals
run -all
