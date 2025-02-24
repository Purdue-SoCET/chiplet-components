module fpga_endpoint_wrapper(
    input logic CLOCK_50,
    input logic [3:0] KEY
);
    switch_if #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2)
    ) sw_if();

    bus_protocol_if bus_if();

    endpoint #(
        .NODE_ID(1),
        .DEPTH(8)
    ) switch1(
        .clk(CLOCK_50),
        .n_rst(!KEY[0]),
        .switch_if(sw_if),
        .bus_if(bus_if)
    );
endmodule
