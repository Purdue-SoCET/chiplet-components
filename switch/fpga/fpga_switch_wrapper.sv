module fpga_switch_wrapper(
    input logic CLOCK_50,
    input logic [3:0] KEY
);
    switch_if #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2)
    ) sw_if();
    switch #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2),
        .BUFFER_SIZE(8),
        .TOTAL_NODES(4),
        .NODE(1)
    ) switch1(
        .clk(CLOCK_50),
        .n_rst(!KEY[0]),
        .sw_if(sw_if)
    );
endmodule
