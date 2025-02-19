`ifndef COUNTER_IF_SVH
`define COUNTER_IF_SVH

interface counter_if #(parameter BITS_WIDTH = 4) (input logic clk); 
    logic nRST;
    logic clear;
    logic count_enable;
    logic [BITS_WIDTH-1:0] overflow_val;
    logic [BITS_WIDTH-1:0] count_out;
    logic overflow_flag;

    modport tester // Set input/output to test
    (
        input count_out, overflow_flag, clk,
        output nRST, clear, count_enable, overflow_val
    );

    modport counter // Set input/output to DUT
    (
        output count_out, overflow_flag,
        input nRST, clear, count_enable, overflow_val, clk
    );

endinterface
`endif