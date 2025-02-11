`include "pipeline_if.sv"

module vc_allocator#(
    parameter int NUM_OUTPORTS,
    parameter int NUM_BUFFERS,
    parameter int NUM_VCS,
    parameter int BUFFER_SIZE /* Buffer size in words */
)(
    input logic clk,
    input logic n_rst,
    pipeline_if.vc pipe_if,
    switch_reg_bank_if.vc rb_if
);
    logic next_sa_final_vc;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            pipe_if.sa_valid <= 0;
            pipe_if.sa_ingress_port <= 0;
            pipe_if.sa_egress_port <= 0;
            pipe_if.sa_final_vc <= 0;
        end else begin
            pipe_if.sa_valid <= pipe_if.vc_valid;
            pipe_if.sa_ingress_port <= pipe_if.vc_ingress_port;
            pipe_if.sa_egress_port <= pipe_if.vc_egress_port;
            pipe_if.sa_final_vc <= next_sa_final_vc;
        end
    end

    always_comb begin
        // Only upgrade VC if we cross a dateline
        next_sa_final_vc = pipe_if.vc_metadata.vc || rb_if.dateline[pipe_if.vc_egress_port];
    end
endmodule
