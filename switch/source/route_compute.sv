`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "route_compute_if.vh"

module route_compute #(
    parameter node_id_t NODE,
    parameter NUM_BUFFERS
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    route_compute_if.route route_if
);

    parameter N_BUFF = 5-$clog2(NUM_BUFFERS);

    pkt_id_t id;
    node_id_t req, dest;
    format_e format;
    logic [7:0] address;
    logic [14:0] cfg_data;



    typedef struct packed {
        logic [$clog2(NUM_BUFFERS)-1:0] out_sel;
        node_id_t                   req;
        node_id_t                   dest;
    } route_lut_t;

    route_lut_t route_lut [TOTAL_NODES*TOTAL_NODES*$clog2(NUM_BUFFERS)];
    route_lut_t next_route_lut [TOTAL_NODES*TOTAL_NODES*$clog2(NUM_BUFFERS)];
    integer i;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            route_if.allocate <= {NUM_OUTPORTS{'0}};
            route_if.out_sel <= {NUM_BUFFERS{'0}};
            route_lut <= '0;
        end else begin
            route_if.allocate <= next_allocate;
            route_if.out_sel <= next_out_sel;
            route_lut <= next_route_lut;
        end
    end

    route_lut_t head_flit;
    assign id = route_if.in_flit[route_if.buffer_sel].id;
    assign head_flit.req = route_if.in_flit[route_if.buffer_sel].req;
    assign head_flit.dest = route_if.in_flit[route_if.buffer_sel].payload[27:23];
    assign format = format_e'route_if.in_flit[route_if.buffer_sel].payload[31:28];
    assign address = route_if.in_flit[route_if.buffer_sel].payload[14:7];
    assign cfg_data = {route_if.in_flit[route_if.buffer_sel].payload[22:15], route_if.in_flit[route_if.buffer_sel].payload[6:0]};
    

    always_comb begin
        next_allocate = route_if.allocate;
        next_out_sel = route_if.out_sel;
        next_route_lut = route_lut;

        if(format == FMT_SWITCH_CFG && dest == NODE) begin
            next_route_lut[address] = cfg_data[14-N_BUFF:0];
        end
        else if(dest == NODE) begin
            next_out_sel[buffer_sel] = '0;
            next_allocate[buffer_sel] = 1'b1;
        end
        else begin
            for(i = 0; i < TOTAL_NODES*TOTAL_NODES*$clog2(NUM_BUFFERS); i++) begin
                if(route_lut[i].req == head_flit.req && route_lut[i].dest == head_flit.dest)begin
                    next_out_sel[buffer_sel] = route_lut[i].out_sel;
                    next_allocate[buffer_sel] = 1'b1;
                end
            end
        end
    end


endmodule