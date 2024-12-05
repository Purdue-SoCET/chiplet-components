`ifndef ARBITRATION_BUFFER_VH
`define ARBITRATION_BUFFER_VH

`include "phy_types_pkg.vh"

interface arbitration_buffer_if;
    parameter COUNTER_SIZE = 4;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    logic CLK, nRST;
    logic ack_write, nack_write, rs0_write, rs1_write, rs2_write, rs3_write, data_write;
    logic ack_cnt_full, nack_cnt_full, rs0_cnt_full, rs1_cnt_full, rs2_cnt_full, rs3_cnt_full, send_data_cnt_full;
    logic start, done, packet_done;
    logic get_data;
    comma_sel_t comma_sel;
    logic [7:0] comma_header_out,rx_header;
    modport arb(
        input CLK, nRST, ack_write, nack_write, rs0_write, rs1_write, rs2_write, rs3_write, data_write,
        input  done, packet_done,rx_header,
        output start,ack_cnt_full, nack_cnt_full, rs0_cnt_full, rs1_cnt_full, rs2_cnt_full, rs3_cnt_full, send_data_cnt_full,
        output get_data,
        output comma_sel,
        output comma_header_out
    );
endinterface

`endif // ARBITRATION_BUFFER_VH