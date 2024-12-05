`ifndef ENDNODE_IF_VH
`define ENDNODE_IF_VH

`include "phy_types_pkg.vh"

interface endnode_if;
    parameter COUNTER_SIZE = 4;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    flit_enc_t enc_flit_rx; //encoded flit from uarts
    logic done_in_rx; //done from uarts
    comma_length_sel_t comma_length_sel_in_rx; //comma length select from uarts
    logic err_in_rx; //error from uarts
    logic done_rx, err_rx, crc_corr_rx; // done rx flit error on rx flit crc_correct output of rx flit
    flit_t flit_rx; //recieved rx flit
    logic start_tx; //start signal to send data 
    flit_t flit_tx; //input flit to transmit updated combinationally on get_packet
    flit_enc_t data_out_tx; //encoded flit for uart
    logic start_out_tx; //start for uart
    comma_length_sel_t comma_sel_tx_out; //select length of packet for uart
    logic done_tx, packet_done_tx; //done tx from uart packet_done_tx from switch for 
    logic get_data; // get next flit to sned on  port

    modport eif(
        input  enc_flit_rx, done_in_rx, comma_length_sel_in_rx, err_in_rx, start_tx, flit_tx, done_tx, packet_done_tx,
        output  get_data, done_rx, err_rx, crc_corr_rx, flit_rx, data_out_tx, start_out_tx, comma_sel_tx_out
    );
endinterface

`endif // ENDNODE_IF_VH