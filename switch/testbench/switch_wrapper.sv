// NUM_OUTPORTS=3
// NUM_BUFFERS=3
// NUM_VCS=2
module switch_wrapper(
    input logic clk, nrst,
    input flit_t [3:0] in_flit,
    input logic [3:0] data_ready_in,
    input logic [3:0] packet_sent,
    output flit_t [3:0] out,
    output logic [3:0] data_ready_out,
    output logic [3:0] [1:0] buffer_available,
    output logic [3:0] [1:0] credit_granted
);
    switch_if #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(8),
        .NUM_VCS(2)
    ) sw_if();

    assign sw_if.in = in_flit;
    assign sw_if.credit_granted = credit_granted[0];
    assign sw_if.data_ready_in = data_ready_in;
    assign sw_if.packet_sent = packet_sent[0];
    assign out = sw_if.out;
    assign data_ready_out = sw_if.data_ready_out;
    assign buffer_available = sw_if.buffer_available;

    switch #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(3),
        .NUM_VCS(2),
        .BUFFER_SIZE(8),
        .TOTAL_NODES(4),
        .NODE(0) // TODO: This should be configurable
    ) s(
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if)
    );

endmodule
