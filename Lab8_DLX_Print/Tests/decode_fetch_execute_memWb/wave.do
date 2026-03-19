onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_hazard_factorial/uut/ARDUINO_RESET_N
add wave -noupdate /tb_hazard_factorial/uut/char
add wave -noupdate /tb_hazard_factorial/uut/char_wr
add wave -noupdate /tb_hazard_factorial/uut/clk_tx_1x
add wave -noupdate /tb_hazard_factorial/uut/fifo_data
add wave -noupdate /tb_hazard_factorial/uut/fifo_empty
add wave -noupdate /tb_hazard_factorial/uut/fifo_full
add wave -noupdate /tb_hazard_factorial/uut/fifo_instr
add wave -noupdate /tb_hazard_factorial/clk
add wave -noupdate /tb_hazard_factorial/uut/fifo_wr
add wave -noupdate /tb_hazard_factorial/uut/tx_read_req
add wave -noupdate /tb_hazard_factorial/uut/char_translator_inst/pop
add wave -noupdate /tb_hazard_factorial/uut/char_translator_inst/push
add wave -noupdate /tb_hazard_factorial/uut/char_translator_inst/state
add wave -noupdate /tb_hazard_factorial/uut/char_translator_inst/stack_empty
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {113 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 383
configure wave -valuecolwidth 40
configure wave -justifyvalue left
configure wave -signalnamewidth 0
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
WaveRestoreZoom {120 ns} {200 ns}
