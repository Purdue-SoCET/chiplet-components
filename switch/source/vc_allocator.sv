`include "vc_allocator_if.sv"

// TODO: Really stupid VC allocator, can probably track vc_taken's to improve
// performance
module vc_allocator#(
    parameter int NUM_OUTPORTS,
    parameter int NUM_BUFFERS,
    parameter int NUM_VCS,
    parameter int BUFFER_SIZE /* Buffer size in words */
)(
    input logic clk,
    input logic n_rst,
    vc_allocator_if.allocator vc_if
);
    always_comb begin
        // Only upgrade VC if we cross a dateline
        vc_if.assigned_vc = vc_if.incoming_vc || vc_if.dateline[vc_if.outport];
    end
endmodule
