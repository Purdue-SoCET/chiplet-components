`include "chiplet_types_pkg.vh"

`define CREATE_TILE(num)                                            \
    bus_protocol_if bus_if_``num``();                               \
    tile #(                                                         \
        .NUM_LINKS(2),                                              \
        .BUFFER_SIZE(BUFFER_SIZE),                                  \
        .PORT_COUNT(PORT_COUNT)                                     \
    ) tile_``num``(                                                 \
        .clk(clk),                                                  \
        .n_rst(n_rst),                                              \
        .packet_recv(),                                             \
        .uart_rx(uart_rx[num - 1]),                                 \
        .uart_tx(uart_tx[num - 1]),                                 \
        .bus_if(bus_if_``num``)                                     \
    );                                                              \
    assign bus_if_``num``.wdata = wdata[num - 1];                   \
    assign bus_if_``num``.wen = wen[num - 1];                       \
    assign bus_if_``num``.ren = ren[num - 1];                       \
    assign bus_if_``num``.addr = addr[num - 1];                     \
    assign bus_if_``num``.strobe = strobe[num - 1];                 \
    assign rdata[num - 1] = bus_if_``num``.rdata;                   \
    assign error[num - 1] = bus_if_``num``.error;                   \
    assign request_stall[num - 1] = bus_if_``num``.request_stall;

parameter NUM_TILES = 4;
parameter NUM_LINKS = 2;

module tile_wrapper #(
    parameter PORT_COUNT = 5,
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    input logic clk, n_rst,
    input logic wen [NUM_TILES-1:0], ren [NUM_TILES-1:0],
    input logic [ADDR_WIDTH-1:0] addr [NUM_TILES-1:0],
    input logic [DATA_WIDTH-1:0] wdata [NUM_TILES-1:0],
    input logic [(DATA_WIDTH/8)-1:0] strobe [NUM_TILES-1:0],
    output logic [DATA_WIDTH-1:0] rdata [NUM_TILES-1:0],
    output logic error [NUM_TILES-1:0],
    output logic request_stall [NUM_TILES-1:0]
);
    localparam BUFFER_SIZE = 8;
    logic [NUM_TILES-1:0] [NUM_LINKS-1:0] [PORT_COUNT-1:0] uart_rx;
    logic [NUM_TILES-1:0] [NUM_LINKS-1:0] [PORT_COUNT-1:0] uart_tx;

    `CREATE_TILE(1)
    `CREATE_TILE(2)
    `CREATE_TILE(3)
    `CREATE_TILE(4)

    assign uart_rx[0][0] = uart_tx[1][0];
    assign uart_rx[0][1] = uart_tx[2][0];

    assign uart_rx[1][0] = uart_tx[0][0];
    assign uart_rx[1][1] = uart_tx[3][0];

    assign uart_rx[2][0] = uart_tx[0][1];
    assign uart_rx[2][1] = uart_tx[3][1];

    assign uart_rx[3][0] = uart_tx[1][1];
    assign uart_rx[3][1] = uart_tx[2][1];
endmodule
