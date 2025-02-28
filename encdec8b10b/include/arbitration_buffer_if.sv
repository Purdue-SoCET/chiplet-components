`ifndef ARBITRATION_BUFFER_VH
`define ARBITRATION_BUFFER_VH

`include "phy_types_pkg.vh"

interface arbitration_buffer_if;
    parameter COUNTER_SIZE = 4;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    logic CLK, nRST;
    logic ack_write,grtcred0_write,grtcred1_write, data_write;
    logic ack_cnt_full,grtcred_0_full,grtcred_1_full, send_data_cnt_full;
    logic start, done, packet_done,send_new_data;
    logic get_data;
    comma_sel_t comma_sel;
    logic [7:0] comma_header_out,rx_header;
    modport arb(
        input CLK, nRST, ack_write, data_write,
        input  done, packet_done,rx_header, grtcred0_write,grtcred1_write,send_new_data,
        output start,ack_cnt_full,grtcred_0_full, grtcred_1_full, send_data_cnt_full,
        output get_data,
        output comma_sel,
        output comma_header_out
    );
endinterface

`endif // ARBITRATION_BUFFER_VH