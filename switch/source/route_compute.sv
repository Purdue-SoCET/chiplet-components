`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"

module route_compute #(
    parameter pkt_id_t NODE,
    parameter BUFFERS
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    route_compute_if.route route_if
);

    pkt_id_t id;
    node_id_t req, dest;
    format_e format;

    typedef struct packed {
        logic [$clog2(BUFFERS)-1:0] out_sel;
        node_id_t                   req;
        node_id_t                   dest;
    } route_lut_t;

    route_lut_t route_lut [TOTAL_NODES*TOTAL_NODES*$clog2(BUFFERS)];
    integer i;

    route_lut_t head_flit;
    assign id = route_if.in_flit[route_if.buffer_sel].id;
    assign head_flit.req = route_if.in_flit[route_if.buffer_sel].req;
    assign head_flit.dest = route_if.in_flit[route_if.buffer_sel].payload[27:23];
    assign route_if.id = id;
    assign format = format_e'route_if.in_flit[route_if.buffer_sel].payload[31:28];
    

    always_comb begin
        if(format == FMT_SWITCH_CFG && dest == NODE) begin

        end
        else if(dest == NODE) begin
            route_if.out_sel = '0;
        end
        else begin
            for(i = 0; i < TOTAL_NODES*TOTAL_NODES*$clog2(BUFFERS); i++) begin
                if(route_lut[i].req == head_flit.req && route_lut[i].dest == head_flit.dest)begin
                    route_if.out_sel = route_lut[i].out_sel;
                end
            end
        end
    end


endmodule