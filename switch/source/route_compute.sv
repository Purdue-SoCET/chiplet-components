`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_pkg.sv"
`include "route_compute_if.sv"

module route_compute #(
    parameter node_id_t NODE,
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS,
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    route_compute_if.route route_if
);
    import chiplet_types_pkg::*;
    import switch_pkg::*;

    localparam N_BUFF = 5-$clog2(NUM_BUFFERS);
    localparam SELECT_SIZE = $clog2(NUM_OUTPORTS) + (NUM_OUTPORTS == 1);

    node_id_t [NUM_BUFFERS-1:0] req, dest;
    logic [NUM_BUFFERS-1:0] next_allocate;
    logic [NUM_BUFFERS-1:0] [SELECT_SIZE-1:0] next_out_sel;

    //TODO Serialize route compute, right now all in parallel
    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            route_if.allocate <= '0;
            route_if.out_sel <= '0;
        end else begin
            route_if.allocate <= next_allocate;
            route_if.out_sel <= next_out_sel;
        end
    end

    route_lut_t [NUM_BUFFERS-1:0] head_flit;
    logic found;

    always_comb begin
        next_allocate = route_if.allocate;
        next_out_sel = route_if.out_sel;

        for(int i = 0; i < NUM_BUFFERS; i++) begin
            head_flit[i].req = route_if.in_flit[i].req;
            head_flit[i].dest = route_if.in_flit[i].payload[27:23];
        end

        for(int i = 0; i < NUM_BUFFERS; i++) begin
            found = 0;
            if (route_if.valid[i]) begin
                if(head_flit[i].dest == NODE) begin
                    next_out_sel[i] = '0;
                    next_allocate[i] = 1'b1;
                end
                else begin
                    for(int j = 0; j < 32; j++) begin
                        if(!found && (route_if.route_lut[j].req == 0 || (route_if.route_lut[j].req == head_flit[i].req)) &&
                            (route_if.route_lut[j].dest == 0 || (route_if.route_lut[j].dest == head_flit[i].dest))) begin
                            next_out_sel[i] = route_if.route_lut[j].out_sel[0+:SELECT_SIZE];
                            next_allocate[i] = 1'b1;
                            found = 1;
                        end
                    end
                end
            end else begin
                next_out_sel[i] = 0;
                next_allocate[i] = 0;
            end
        end
    end


endmodule
