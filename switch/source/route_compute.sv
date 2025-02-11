`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_pkg.sv"
`include "pipeline_if.sv"

module route_compute #(
    parameter node_id_t NODE,
    parameter NUM_OUTPORTS,
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    pipeline_if.rc pipe_if,
    switch_reg_bank_if.rc rb_if
);
    import chiplet_types_pkg::*;
    import switch_pkg::*;

    localparam EGRESS_SIZE = $clog2(NUM_OUTPORTS) + (NUM_OUTPORTS == 1);

    node_id_t req, dest;
    logic found;
    logic [EGRESS_SIZE-1:0] next_vc_egress_port;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            pipe_if.vc_valid <= 0;
            pipe_if.vc_metadata <= 0;
            pipe_if.vc_ingress_port <= 0;
            pipe_if.vc_egress_port <= 0;
        end else begin
            pipe_if.vc_valid <= pipe_if.rc_valid;
            pipe_if.vc_metadata <= pipe_if.rc_metadata;
            pipe_if.vc_ingress_port <= pipe_if.rc_ingress_port;
            pipe_if.vc_egress_port <= next_vc_egress_port;
        end
    end

    always_comb begin
        next_vc_egress_port = 0;
        found = 0;

        req = pipe_if.rc_metadata.req;
        dest = pipe_if.rc_dest;

        if (dest == NODE) begin
            next_vc_egress_port = '0;
        end else begin
            for(int i = 0; i < 32; i++) begin
                if(!found && (rb_if.route_lut[i].req == 0 || (req == rb_if.route_lut[i].req)) &&
                             (rb_if.route_lut[i].dest == 0 || dest == 0 || (dest == rb_if.route_lut[i].dest))) begin
                    next_vc_egress_port = rb_if.route_lut[i].out_sel[0+:EGRESS_SIZE];
                    found = 1;
                end
            end
        end
    end
endmodule
