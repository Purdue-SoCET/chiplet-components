`ifndef STACK_IF_SVH
`define STACK_IF_SVH

interface stack_if #(type T = logic [7:0],parameter DEPTH = 8) (input logic clk);
    // list of inputs
    logic nRST;
    logic push;
    logic pop;
    logic clear;
    T wdata;
    // list of outputs
    logic empty;
    logic full;
    logic overflow;
    logic underflow;
    logic [$clog2(DEPTH):0] count;
    T rdata;

    modport stack (input clk, nRST, push, pop, clear, wdata,
                   output empty, full, overflow, underflow, count, rdata);

endinterface
    

`endif
