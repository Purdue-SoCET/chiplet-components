`ifndef PHY_MANAGER_TX_IF_VH
`define PHY_MANAGER_TX_IF_VH

`include "phy_types_pkg.vh"
`include "chiplet_types_pkg.vh"

interface phy_manager_tx_if;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

    logic start, done, packet_done;
    logic ack_write,  grtcred0_write, grtcred1_write, data_write;
    logic get_data;
    logic ack_cnt_full,grtcred0_full,grtcred1_full, send_data_cnt_full,new_flit;
    comma_sel_t comma_sel;
    comma_length_sel_t comma_length_sel_out;
    flit_enc_t enc_flit;
    flit_t flit;
    logic start_out;
    logic [7:0] rx_header;
    modport tx(
        input  new_flit, start, done, packet_done, ack_write, data_write, grtcred1_write, grtcred0_write, flit,rx_header,
        output enc_flit, comma_sel, comma_length_sel_out, start_out,
        output get_data,
        output ack_cnt_full, grtcred1_full, grtcred0_full,send_data_cnt_full
    );
endinterface

`endif // PHY_MANAGER_TX_IF_VH