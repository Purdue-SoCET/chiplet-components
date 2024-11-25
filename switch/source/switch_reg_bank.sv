`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_reg_bank_if.vh"

module switch_reg_bank #(
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS,
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    switch_reg_bank_if.reg_bank rb_if
);

endmodule