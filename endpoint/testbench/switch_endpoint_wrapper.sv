`define POSEDGE(name, sig)                      \
    logic name;                                 \
    socetlib_edge_detector DETECT_``name`` (    \
        .CLK(clk),                              \
        .nRST(n_rst),                            \
        .signal(sig),                           \
        .pos_edge(name),                        \
        .neg_edge()                             \
    );

`include "chiplet_types_pkg.vh"
`include "switch_if.vh"

module switch_endpoint_wrapper #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input logic clk, n_rst,
    // Bus side signals
    input logic wen, ren, 
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic [(DATA_WIDTH/8)-1:0] strobe,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic error, request_stall,
    // Switch side signals to write directly to switch
    input chiplet_types_pkg::flit_t in_flit,
    output logic data_ready_in,
    // Switch side signals to read directly from the switch
    output chiplet_types_pkg::flit_t out_flit,
    output data_ready_out,

    input logic packet_sent
);
    switch_if #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2)
    ) sw_if ();

    switch #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2),
        .BUFFER_SIZE(8),
        .TOTAL_NODES(4),
        .NODE(1) // TODO: This should be configurable
    ) switch1 (
        .clk(clk),
        .n_rst(n_rst),
        .sw_if(sw_if)
    );

    bus_protocol_if bus_if();

    endpoint #(
        .NUM_MSGS(4),
        .NODE_ID(1),
        .DEPTH(8)
    ) endpoint1 (
        .clk(clk),
        .n_rst(n_rst),
        .switch_if(sw_if),
        .bus_if(bus_if)
    );

    assign bus_if.wen = wen;
    assign bus_if.ren = ren;
    assign bus_if.addr = addr;
    assign bus_if.wdata = wdata;
    assign bus_if.strobe = strobe;
    assign rdata = bus_if.rdata;
    assign error = bus_if.error;
    assign request_stall = bus_if.request_stall;

    assign sw_if.in[1] = in_flit;
    assign data_ready_in = sw_if.data_ready_in[1];

    assign out_flit = sw_if.out[1];
    assign data_ready_out = sw_if.data_ready_out[1];

    assign sw_if.packet_sent[1] = packet_sent;
endmodule
