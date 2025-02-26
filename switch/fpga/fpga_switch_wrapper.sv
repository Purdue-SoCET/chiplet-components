module fpga_switch_wrapper(
    input logic CLOCK_50,
    input logic [3:0] KEY
);
    import chiplet_types_pkg::*;

    localparam NUM_BUFFERS=4;

    flit_t [NUM_BUFFERS-1:0] out /* synthesis syn_noprune */;
    switch_if #(
        .NUM_OUTPORTS(NUM_BUFFERS),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_VCS(2)
    ) sw_if();

    always_ff @(posedge CLOCK_50, negedge KEY[0]) begin
        if (!KEY[0]) begin
            out <= 0;
        end else begin
            out <= sw_if.out;
        end
    end
    assign sw_if.in[0] = {40{KEY[1]}};
    assign sw_if.in[NUM_BUFFERS-1:1] = out[NUM_BUFFERS-1:1];
    assign sw_if.data_ready_in = {NUM_BUFFERS{KEY[2]}};
    assign sw_if.credit_granted = {NUM_BUFFERS{KEY[3]}};
    assign sw_if.packet_sent = {NUM_BUFFERS{KEY[3]}};
    switch #(
        .NUM_OUTPORTS(NUM_BUFFERS),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_VCS(2),
        .BUFFER_SIZE(8),
        .TOTAL_NODES(4),
        .NODE(1)
    ) switch1(
        .clk(CLOCK_50),
        .n_rst(KEY[0]),
        .sw_if(sw_if)
    );
endmodule
