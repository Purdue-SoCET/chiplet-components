`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_pkg.sv"
`include "route_compute_if.sv"

module route_compute #(
    parameter node_id_t NODE,
    parameter NUM_OUTPORTS,
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    route_compute_if.route route_if
);
    import chiplet_types_pkg::*;
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_OUTPORTS) + (NUM_OUTPORTS == 1);

    node_id_t req, dest;
    logic strict_found, loose_found;
    logic [SELECT_SIZE-1:0] strict_sel, loose_sel;

    always_comb begin
        route_if.out_sel = 0;
        strict_found = 0;
        strict_sel = 0;
        loose_found = 0;
        loose_sel = 0;

        req = route_if.head_flit.req;
        dest = route_if.head_flit.payload[27:23];

        if (dest == NODE) begin
            route_if.out_sel = '0;
        end else begin
            for(int i = 0; i < 32; i++) begin
                if (!strict_found && route_if.route_lut[i].valid &&
                    (route_if.route_lut[i].lut.req == 0 || (req == route_if.route_lut[i].lut.req)) &&
                    (route_if.route_lut[i].lut.dest == 0 || dest == 0 || (dest == route_if.route_lut[i].lut.dest))) begin
                    strict_sel = route_if.route_lut[i].lut.out_sel[0+:SELECT_SIZE];
                    strict_found = rc_if.buffer_available[strict_sel];
                end

                if (!loose_found && route_if.route_lut[i].valid &&
                    (route_if.route_lut[i].lut.req == 0 || (req == route_if.route_lut[i].lut.req)) &&
                    (route_if.route_lut[i].lut.dest == 0 || dest == 0 || (dest == route_if.route_lut[i].lut.dest))) begin
                    loose_sel = route_if.route_lut[i].lut.out_sel[0+:SELECT_SIZE];
                    loose_found = 1;
                end
            end

            if (strict_found) begin
                rc_if.out_sel = strict_sel;
            end else begin
                rc_if.out_sel = loose_sel;
            end
        end
    end
endmodule
