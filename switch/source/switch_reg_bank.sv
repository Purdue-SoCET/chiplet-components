`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_pkg.sv"
`include "switch_reg_bank_if.sv"

module switch_reg_bank #(
    parameter NODE,
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS,
    parameter TABLE_SIZE,
    parameter TOTAL_NODES
) (
    input logic clk, n_rst,
    switch_reg_bank_if.reg_bank rb_if
);
    import chiplet_types_pkg::*;
    import switch_pkg::*;

    logic [NUM_BUFFERS-1:0] [7:0] address;
    logic [NUM_BUFFERS-1:0] [14:0] cfg_data;
    format_e [NUM_BUFFERS-1:0] format;
    node_id_t [NUM_BUFFERS-1:0] dest;

    route_lut_t [TABLE_SIZE-1:0] next_route_lut;
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

    always_comb begin
        next_dateline = rb_if.dateline;
        next_route_lut = rb_if.route_lut;

        for (int i = 0; i < NUM_BUFFERS; i++) begin
            format[i] = format_e'(rb_if.in_flit[i].payload[31:28]);
            address[i] = rb_if.in_flit[i].payload[14:7];
            dest[i] = rb_if.in_flit[i].payload[27:23];
            cfg_data[i] = {rb_if.in_flit[i].payload[22:15], rb_if.in_flit[i].payload[6:0]};

            if(format[i] == FMT_SWITCH_CFG && dest[i] == NODE) begin
                if(address[i] <= 8'h10) begin
                    next_route_lut[address[i]] = route_lut_t'(cfg_data[i]);
                end
                else if(address[i] == 8'h15) begin
                    next_dateline = cfg_data[i][NUM_OUTPORTS-1:0];
                end
            end
        end
    end

endmodule
