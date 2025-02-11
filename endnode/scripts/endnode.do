onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_endnode/transmitter_uart/tx/CLK
add wave -noupdate /tb_endnode/transmitter_uart/tx/nRST
add wave -noupdate -expand -group rx_uart -color {Slate Blue} /tb_endnode/rx_uart/rx_if/uart_in
add wave -noupdate -expand -group rx_uart -color {Slate Blue} /tb_endnode/rx_uart/rx_if/data
add wave -noupdate -expand -group rx_uart -color {Slate Blue} /tb_endnode/rx_uart/rx_if/comma_sel
add wave -noupdate -expand -group rx_uart -color {Slate Blue} /tb_endnode/rx_uart/rx_if/done
add wave -noupdate -expand -group rx_uart -color {Slate Blue} /tb_endnode/rx_uart/rx_if/rx_err
add wave -noupdate -expand -group tx_uart_out -color {Medium Orchid} /tb_endnode/transmitter_uart/tx/shift_reg_out
add wave -noupdate -expand -group tx_uart_out -color {Medium Orchid} /tb_endnode/transmitter_uart/tx/comma_sel_reg
add wave -noupdate -expand -group tx_uart_out -color {Medium Orchid} /tb_endnode/transmitter_uart/tx/state
add wave -noupdate -expand -group tx_uart_out -color {Medium Orchid} /tb_endnode/transmitter_uart/tx/n_state
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx/arb_if/comma_sel
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/start
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/done
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/packet_done
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/send_data_cnt_full
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/comma_sel
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/comma_length_sel_out
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/enc_flit
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/flit
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/start_out
add wave -noupdate -expand -group phy_tx_out -color Pink /tb_endnode/transmitter/phy_tx_if/rx_header
add wave -noupdate -expand -group {phy mananger_Rx} -expand /tb_endnode/recieveer/phy_rx/dec/flit_data
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/crc_done
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/dec/seen_start_comma
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/crc_clear
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/crc_update
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/crc_in
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/crc_out
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/cntr_clear
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/cntr_enable
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/overflow_flag_cntr
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/count_out
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/state
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/dec_if/flit
add wave -noupdate -expand -group {phy mananger_Rx} /tb_endnode/recieveer/phy_rx/n_state
add wave -noupdate -expand -group uart_tx_in /tb_endnode/recieveer/phy_rx/dec_if/curr_packet_size
add wave -noupdate -expand -group uart_tx_in /tb_endnode/uart_tx_rx_if/uart_in
add wave -noupdate -expand -group uart_tx_in /tb_endnode/uart_tx_rx_if/comma_sel
add wave -noupdate -expand -group uart_tx_in /tb_endnode/uart_tx_rx_if/done
add wave -noupdate -expand -group uart_tx_in /tb_endnode/uart_tx_rx_if/rx_err
add wave -noupdate /tb_endnode/transmitter/phy_tx_if/ack_cnt_full
add wave -noupdate /tb_endnode/transmitter/phy_rx_if/packet_done
add wave -noupdate /tb_endnode/transmitter/err_store
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {13854090 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 391
configure wave -valuecolwidth 201
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
configure wave -timelineunits ps
update
WaveRestoreZoom {13434141 ps} {13946055 ps}
