`include "chiplet_types_pkg.vh"

module req_fifo#() (
    input logic clk, n_rst,
    input logic crc_valid,
    input logic [4:0] req
    bus_protocol_if.peripheral_vital bus_if
);

    logic ren;

    socetlib_fifo #(.T(logic[4:0]), .DEPTH(16)) requestor_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(crc_valid),
        .REN(ren),
        .clear(),
        .wdata(req),
        .full(),
        .empty(),
        .underrun(),
        .overrun(),
        .count(),
        .rdata(),
    );





endmodule