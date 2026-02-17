onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -expand -group {Testbench signals} /tb_fetch_decode_execute_memwb/clk
add wave -noupdate -expand -group {Testbench signals} /tb_fetch_decode_execute_memwb/tb_rst
add wave -noupdate -expand -group {Fetch signals} /tb_fetch_decode_execute_memwb/uut/fetch_inst/PC_counter/data_out
add wave -noupdate -expand -group {Fetch signals} /tb_fetch_decode_execute_memwb/uut/fetch_inst/IMEM/q
add wave -noupdate -expand -group Decode /tb_fetch_decode_execute_memwb/uut/decode_inst/instr_reg/data_out
add wave -noupdate -expand -group Decode /tb_fetch_decode_execute_memwb/uut/decode_inst/reg_file/reg_read_data1
add wave -noupdate -expand -group Decode /tb_fetch_decode_execute_memwb/uut/decode_inst/reg_file/reg_read_data2
add wave -noupdate -expand -group Decode /tb_fetch_decode_execute_memwb/uut/decode_inst/sign_extER/output_data
add wave -noupdate -group Execute /tb_fetch_decode_execute_memwb/uut/execute_inst/MUXXY1/A
add wave -noupdate -group Execute -expand -group Branch_en /tb_fetch_decode_execute_memwb/uut/execute_inst/branch_check_reg/data_out
add wave -noupdate -group Execute -expand -group ALU_out /tb_fetch_decode_execute_memwb/uut/execute_inst/ALU_out_reg/data_out
add wave -noupdate -group Execute -expand -group instruction /tb_fetch_decode_execute_memwb/uut/execute_inst/instr_reg/data_out
add wave -noupdate -group Execute -expand -group {rs2 data} /tb_fetch_decode_execute_memwb/uut/execute_inst/rs2_reg/data_out
add wave -noupdate -group Execute /tb_fetch_decode_execute_memwb/uut/jump_addr
add wave -noupdate -expand -group Memory /tb_fetch_decode_execute_memwb/uut/memory_inst/DATA_MEM/address
add wave -noupdate -expand -group Memory /tb_fetch_decode_execute_memwb/uut/memory_inst/DATA_MEM/wren
add wave -noupdate -expand -group Memory /tb_fetch_decode_execute_memwb/uut/memory_inst/DATA_MEM/data
add wave -noupdate -expand -group Memory /tb_fetch_decode_execute_memwb/uut/memory_inst/DATA_MEM/q
add wave -noupdate -expand -group Memory /tb_fetch_decode_execute_memwb/uut/memory_inst/reg_ALU_reg/data_out
add wave -noupdate -expand -group Memory /tb_fetch_decode_execute_memwb/uut/memory_inst/instr_addr_reg/data_out
add wave -noupdate -expand -group WB /tb_fetch_decode_execute_memwb/uut/write_back_inst/wb_addr
add wave -noupdate -expand -group WB /tb_fetch_decode_execute_memwb/uut/write_back_inst/wb_data
add wave -noupdate -expand -group WB /tb_fetch_decode_execute_memwb/uut/write_back_inst/wb_en
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {198 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 259
configure wave -valuecolwidth 97
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {57 ns} {249 ns}
