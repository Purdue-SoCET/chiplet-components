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
    input logic wen, ren, 
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic [(DATA_WIDTH/8)-1:0] strobe,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic error, request_stall,
    input logic [1:0] packet_sent,
    input flit_t in_flit,
    input logic data_ready_in,
    output flit_t out,
    output logic data_ready_out,
    output logic credit_granted
);
    switch_if #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2)
    ) sw_if1 ();

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
        .sw_if(sw_if1)
    );

    phy_manager_if.rx_switch rx_switch_if();
    bus_protocol_if.peripheral_vital bus_if();

    endpoint #(
        .NUM_MSGS(NUM_MSGS)
    ) endpoint1 (
        .clk(clk),
        .n_rst(n_rst),
        .data_ready(sw_if1.data_ready_out[0]),
        .flit(sw_if1.out[0]),
        .switch_if(rx_switch_if),
        .bus_if(bus_if)
    );

    rx_switch_if.buffer_full = sw_if1.buffer_available[0];
    sw_if1.data_ready_in[0] = rx_switch_if.data_ready;
    sw_if1.data_ready_in[1] = data_ready_in;
    sw_if1.in[0] = rx_switch_if.flit;
    sw_if1.in[1] = in_flit;
    sw_if1.credit_granted = credit_granted;
    sw_if1.packet_sent = packet_sent;
    data_ready_out = sw_if1.data_ready_out[0];
    out = sw_if1.out[0];
    //endpoint in flit = sw_if1.out[0];
    bus_if.wen = wen;
    bus_if.ren = ren,;
    bus_if.addr = addr;
    bus_if.wdata = wdata;
    bus_if.strobe = strobe;
    rdata = bus_if.rdata;
    error = bus_if.error;
    request_stall = bus_if.request_stall;




endmodule