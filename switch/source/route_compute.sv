`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "route_compute_if.sv"

module route_compute #(
    parameter node_id_t NODE,
    parameter NUM_BUFFERS
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    route_compute_if.route route_if
);

    parameter N_BUFF = 5-$clog2(NUM_BUFFERS);

    pkt_id_t [NUM_BUFFERS-1:0] id;
    node_id_t [NUM_BUFFERS-1:0] req, dest;
    format_e [NUM_BUFFERS-1:0] format;
    logic [7:0] address[NUM_BUFFERS-1:0];
    logic [14:0] cfg_data[NUM_BUFFERS-1:0];

    // route_lut_t route_lut [TOTAL_NODES*TOTAL_NODES*$clog2(NUM_BUFFERS)];
    // route_lut_t next_route_lut [TOTAL_NODES*TOTAL_NODES*$clog2(NUM_BUFFERS)];

    integer i;
    //TODO Serialize route compute, right now all in parallel
    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            route_if.allocate <= {NUM_OUTPORTS{'0}};
            route_if.out_sel <= {NUM_BUFFERS{'0}};
            //route_lut <= '0;
        end else begin
            route_if.allocate <= next_allocate;
            route_if.out_sel <= next_out_sel;
            //route_lut <= next_route_lut;
        end
    end

    route_lut_t [NUM_BUFFERS-1:0] head_flit;

    for(int j = 0; j < NUM_BUFFERS; j++) begin
        assign id[j] = route_if.in_flit[j].id;
        assign head_flit[j].req = route_if.in_flit[j].req;
        assign head_flit[j].dest = route_if.in_flit[j].payload[27:23];
        assign format[j] = format_e'route_if.in_flit[j].payload[31:28];
        assign address[j] = route_if.in_flit[j].payload[14:7];
        assign cfg_data[j] = {route_if.in_flit[j].payload[22:15], route_if.in_flit[j].payload[6:0]};
    end
    int k;
    always_comb begin
        next_allocate = route_if.allocate;
        next_out_sel = route_if.out_sel;
        //next_route_lut = route_lut;

        for(k = 0; k < NUM_BUFFERS; k++) begin
            if(format[k] == FMT_SWITCH_CFG && dest[k] == NODE) begin
                //next_route_lut[address[k]] = cfg_data[k][14-N_BUFF:0];
                next_allocate = 1'b0;
            end
            else if(dest[k] == NODE) begin
                next_out_sel[k] = '0;
                next_allocate[k] = 1'b1;
            end
            else begin
                for(i = 0; i < TOTAL_NODES*TOTAL_NODES*$clog2(NUM_BUFFERS); i++) begin
                    if(route_lut[i].req == head_flit[k].req && route_lut[i].dest == head_flit[k].dest)begin
                        next_out_sel[k] = route_lut[i].out_sel;
                        next_allocate[k] = 1'b1;
                    end
                end
            end
        end
    end


endmodule