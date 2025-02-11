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
    logic found;

    always_comb begin
        route_if.out_sel = 0;
        found = 0;

        req = route_if.head_flit.req;
        dest = route_if.head_flit.payload[27:23];

        if (dest == NODE) begin
            route_if.out_sel = '0;
        end else begin
            for(int i = 0; i < 32; i++) begin
                if(!found && (route_if.route_lut[i].req == 0 || (req == route_if.route_lut[i].req)) &&
                             (route_if.route_lut[i].dest == 0 || dest == 0 || (dest == route_if.route_lut[i].dest))) begin
                    route_if.out_sel = route_if.route_lut[i].out_sel[0+:SELECT_SIZE];
                    found = 1;
                end
            end
        end
    end
endmodule
