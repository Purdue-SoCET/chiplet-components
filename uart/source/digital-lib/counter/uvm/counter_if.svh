`ifndef COUNTER_IF_SVH
`define COUNTER_IF_SVH

interface counter_if #(parameter BITS_WIDTH=4) (input logic clk);
    logic nRST;
    logic clear;
    logic count_enable;
    logic [BITS_WIDTH - 1 : 0] overflow_val;
    logic [BITS_WIDTH - 1 : 0] count_out;
    logic overflow_flag;
    logic check; 
    int enable_time;
    
    assign count_enable = 1'b1;
modport test ( // test
    input overflow_flag,count_out,clk,
    output nRST, clear, count_enable, overflow_val, check, enable_time
);
modport counter ( // DUT
    output overflow_flag, count_out,
    input overflow_val, count_enable, clear, nRST, clk
);

endinterface
`endif
