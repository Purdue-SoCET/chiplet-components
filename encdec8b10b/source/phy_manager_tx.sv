`timescale 1ns / 10ps

module phy_manager_tx #(
    parameter PORTCOUNT = 5
)(
    input logic CLK,
    input logic nRST,
    phy_manager_tx_if.tx phy_if
);
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

    arbitration_buffer_if arb_if();
    arbitration_buffer arb_buff(
        .CLK(CLK),
        .nRST(nRST),
        .arb_if(arb_if)
    );

    wrap_enc_8b_10b_if enc_if();
    wrap_enc_8b_10b enc(
        .CLK(CLK),
        .nRST(nRST),
        .enc_if(enc_if)
    );

    assign enc_if.comma_sel = arb_if.comma_sel;
    assign enc_if.flit = (arb_if.comma_sel == DATA_SEL || arb_if.comma_sel == END_PACKET_SEL || arb_if.comma_sel == START_PACKET_SEL) ? phy_if.flit : flit_t'({arb_if.comma_header_out,32'b0});
    assign enc_if.start = arb_if.start;

    assign phy_if.enc_flit = enc_if.flit_out;
    assign phy_if.start_out = enc_if.start_out;

    assign arb_if.done = phy_if.done;
    assign arb_if.packet_done = phy_if.packet_done;
    assign arb_if.ack_write = phy_if.ack_write;
    // assign arb_if.nack_write = phy_if.nack_write;
    assign arb_if.grtcred0_write = phy_if.grtcred0_write;
    assign arb_if.grtcred1_write = phy_if.grtcred1_write;
    assign arb_if.data_write = phy_if.data_write;
    assign arb_if.rx_header = phy_if.rx_header;
    assign arb_if.send_new_data = phy_if.new_flit;
    assign arb_if.flit_data = phy_if.flit.payload;
    assign phy_if.get_data = arb_if.get_data;
    //add in logic for these later could be bugy prevents bugs
    assign phy_if.ack_cnt_full = arb_if.ack_cnt_full;
    assign phy_if.grtcred0_full = arb_if.grtcred_0_full;
    assign phy_if.grtcred1_full = arb_if.grtcred_1_full;
    assign phy_if.send_data_cnt_full = arb_if.send_data_cnt_full;
    assign phy_if.comma_length_sel_out = enc_if.comma_length_sel_out;
endmodule
