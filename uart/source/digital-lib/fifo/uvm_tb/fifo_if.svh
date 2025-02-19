`ifndef FIFO_IF_SVH
`define FIFO_IF_SVH

interface fifo_if #(type T = logic [7:0], parameter DEPTH = 8);
    // inputs
    logic clk;
    logic nRST;
    logic WEN;
    logic REN;
    logic clear;
    T wdata;

    // outputs
    logic full;
    logic empty;
    logic overrun;
    logic underrun;
    logic [$clog2(DEPTH) - 1:0] count;
    T rdata;

    modport fifo (
        output full, empty, underrun, overrun, count, rdata,
        input clk, nRST, WEN, REN, clear, wdata
    );
endinterface

`endif
