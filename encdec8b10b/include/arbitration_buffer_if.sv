`ifndef ARBITRATION_BUFFER_VH
`define ARBITRATION_BUFFER_VH

`include "phy_types_pkg.vh"

interface arbitration_buffer_if #(
    parameter COUNTER_SIZE = 4
);
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

    // Input signals
    logic ack_write, grtcred0_write, grtcred1_write, data_write;
    logic nack_baud_write, baud_comma_write, req_ctrl_comma_write, grt_ctrl_comma_write;
    logic done, packet_done, send_new_data, baud_set;
    logic [7:0] rx_header;

    // Output signals
    logic start, get_data, set_baud;
    logic ack_cnt_full, grtcred_0_full, grtcred_1_full, send_data_cnt_full;
    logic nack_baud_full, baud_comma_full, req_ctrl_comma_full, grt_ctrl_comma_full;

    comma_sel_t comma_sel;
    logic [7:0] comma_header_out;
    chiplet_word_t flit_data;

    // Modport for arbitration control
    modport arb(
        input  ack_write, data_write, flit_data, done, packet_done, rx_header, 
               grtcred0_write, grtcred1_write, send_new_data, nack_baud_write, 
               baud_comma_write, req_ctrl_comma_write, grt_ctrl_comma_write, baud_set,
        output start, ack_cnt_full, grtcred_0_full, grtcred_1_full, send_data_cnt_full, 
               nack_baud_full, baud_comma_full, req_ctrl_comma_full, grt_ctrl_comma_full,
               get_data, comma_sel, comma_header_out, set_baud
    );

endinterface

`endif // ARBITRATION_BUFFER_VH
