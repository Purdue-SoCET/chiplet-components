onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_top/dut_if/clk
add wave -noupdate /tb_top/dut_if/nRST
add wave -noupdate /tb_top/dut_if/serial_in
add wave -noupdate -radix binary /tb_top/dut_if/parallel_out
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {124595 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
configure wave -timelineunits ps
update
WaveRestoreZoom {32564 ps} {358212 ps}
