
`ifndef SR_IF_SVH
`define SR_IF_SVH

interface sr_if #(parameter NUM_BITS = 4) (input logic clk);
  logic nRST;
  logic shift_en;
  logic parallel_en;
  logic serial_in;
  logic [NUM_BITS - 1:0] parallel_in;
  logic serial_out;
  logic [NUM_BITS -1:0] parallel_out;
  logic check;
  
  modport tb( // Define signal direction for testbench
    input parallel_out, serial_out, clk,
    output nRST, shift_en, parallel_en, serial_in, parallel_in, check 
);

  modport dut( // Define signal direction for DUT
    input nRST, shift_en, parallel_en, serial_in, parallel_in, clk,
    output parallel_out, serial_out
  );

endinterface
`endif

	

