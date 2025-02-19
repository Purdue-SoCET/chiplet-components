module fifo_wrapper(
    input logic clk,
    input logic nrst,
    input logic wen,
    input logic ren,
    input logic clear,
    input logic [31:0] wdata,
    output logic full,
    output logic empty,
    output logic underrun,
    output logic overrun,
    output logic [3:0] count,
    output logic [31:0] rdata
);
    socetlib_fifo #(
        .T(logic [31:0]),
        .DEPTH(8)
    ) fifo (
        .CLK(clk),
        .nRST(nrst),
        .WEN(wen),
        .REN(ren),
        .clear(clear),
        .wdata(wdata),
        .full(full),
        .empty(empty),
        .underrun(underrun),
        .overrun(overrun),
        .count(count),
        .rdata(rdata)
    );
endmodule
