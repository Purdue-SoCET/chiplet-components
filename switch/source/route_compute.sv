`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"

module route_compute #(
    parameter pkt_id_t NODE
) (
    input logic clk, n_rst,
    route_compute_if.route route_if
);
    pkt_id_t id;
    node_id_t req, dest;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin

        end
        else begin
            
        end
    end

    assign id = route_if.in_flit.id;
    assign req = route_if.in_flit.req;
    assign dest = node_id_t'route_if.in_flit.payload[27:23];


    always_comb begin
        if(dest == NODE) begin

        end
        else begin

        end
    end


endmodule