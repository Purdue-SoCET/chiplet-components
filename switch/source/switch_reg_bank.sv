`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_reg_bank_if.vh"

module switch_reg_bank #(
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS,
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    switch_reg_bank_if.reg_bank rb_if
);

    import chiplet_types_pkg::*;

    typedef struct packed {
        logic [$clog2(NUM_BUFFERS)-1:0] out_sel;
        node_id_t                   req;
        node_id_t                   dest;
    } route_lut_t;

    logic [7:0] [NUM_BUFFERS-1:0] address;
    logic [14:0] [NUM_BUFFERS-1:0] cfg_data;
    format_e [NUM_BUFFERS-1:0] format;
    node_id_t [NUM_BUFFERS-1:0] dest;

    route_lut_t next_route_lut [TOTAL_NODES*TOTAL_NODES*$clog2(NUM_BUFFERS)];
    logic [NUM_OUTPORTS-1:0] next_dateline;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            rb_if.dateline <= '0;
            rb_if.route_lut <= '0;
        end else begin
            rb_if.dateline <= next_dateline;
            rb_if.route_lut <= next_route_lut;
        end
    end

    for(int i; i < NUM_BUFFERS, i++) begin
        format[i] = format_e'route_if.in_flit[i].payload[31:28];
        address[j] = route_if.in_flit[j].payload[14:7];
        dest = route_if.in_flit[j].payload[27:23];

        next_dateline = rb_if.dateline;
        next_route_lut = rb_if.route_lut;

        if(format[i] == FMT_SWITCH_CFG && dest[i] == NODE) begin
            if(address[i] > 8'h00 && address[i] < 8'h10) begin
                next_route_lut[address[i]] = cfg_data[i][14-N_BUFF:0];
            end
            else if(address[i] == 8'h15) begin
                next_dateline = cfg_data[NUM_OUTPORTS-1:0];
            end
        end
    end

endmodule