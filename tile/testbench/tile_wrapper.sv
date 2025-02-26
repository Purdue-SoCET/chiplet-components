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


module tile_wrapper #(
    parameter PORT_COUNT = 5,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)
(
    input logic clk, n_rst,
    input logic [PORT_COUNT-1:0] uart_rx,
    output logic [PORT_COUNT-1:0] uart_tx,
    input logic wen, ren, 
    input logic [ADDR_WIDTH-1:0] addr,
    input logic [DATA_WIDTH-1:0] wdata,
    input logic [(DATA_WIDTH/8)-1:0] strobe,
    output logic [DATA_WIDTH-1:0] rdata,
    output logic error, request_stall,
);
    localparam BUFFER_SIZE = 8;
    bus_protocol_if bus_if();

    tile #(
        .NUM_LINKS(2),
        .BUFFER_SIZE(BUFFER_SIZE),
        .PORT_COUNT(PORT_COUNT)
    ) tile1(
        .clk(clk),
        .n_rst(n_rst),
        .uart_rx(uart_rx),
        .uart_tx(uart_tx),
        .bus_if(bus_if)
    );

    assign bus_if.wdata = wdata;
    assign bus_if.wen = wen;
    assign bus_if.ren = ren;
    assign bus_if.addr = addr;
    assign bus_if.strobe = strobe;
    assign rdata = bus_if.rdata;
    assign error = bus_if.error;
    assign request_stall = bus_if.request_stall;


endmodule