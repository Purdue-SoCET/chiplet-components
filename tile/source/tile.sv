`timescale 1ns / 10ps

module tile #(
    parameter NUM_LINKS,
    parameter int BUFFER_SIZE,
) (
    input clk, n_rst,
    bus_protocol_if.peripheral_vital bus_if
    // TODO: uart interface
);
    parameter NUM_VCS = 2;
    parameter BUFFER_SIZE = 8;

    switch_if #(
        .NUM_OUTPORTS(NUM_LINKS),
        .NUM_BUFFERS(NUM_LINKS),
        .NUM_VCS(NUM_VCS)
    ) sw_if ();

    switch #(
        .NUM_OUTPORTS(NUM_LINKS),
        .NUM_BUFFERS(NUM_LINKS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE),
        .TOTAL_NODES(4),
        .NODE(1) // TODO: This should be configurable
    ) switch (
        .clk(clk),
        .n_rst(n_rst),
        .sw_if(sw_if)
    );

    endpoint #(
        .NUM_MSGS(4),
        .NODE_ID(1),
        .DEPTH(BUFFER_SIZE)
    ) endpoint1 (
        .clk(clk),
        .n_rst(n_rst),
        .switch_if(sw_if),
        .bus_if(bus_if)
    );
endmodule
