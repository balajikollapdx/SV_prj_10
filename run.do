#vlib work
#vlog ECC.sv +acc
#vlog Golden_Ecc.sv +acc
#vlog Testbench.sv +acc
#vsim work.top
#add wave -r *
#run -all

vlib work
vdel -all
vlib work 

vmap work work
vlog -coveropt 3 +cover +acc ECC.sv Golden_Ecc.sv Testbench.sv
vsim -coverage -vopt work.top -c -do "coverage save -onexit -directive -codeAll coverage1ucdb.ucdb; run -all"
vcover report -html coverage1ucdb.ucdb
