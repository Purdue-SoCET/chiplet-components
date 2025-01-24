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

    switch_cfg_hdr_t switch_cfg;
    logic [14:0] cfg_data;

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

        switch_cfg = switch_cfg_hdr_t'(rb_if.in_flit.payload);
        cfg_data = {switch_cfg.data_hi, switch_cfg.data_lo};

        if(switch_cfg.format == FMT_SWITCH_CFG) begin
            // TODO: claiming here will likely make the vc allocator on
            // the other side of the link become unsynchronized
            if(switch_cfg.addr <= 8'h10) begin
                next_route_lut[switch_cfg.addr] = route_lut_t'(cfg_data);
            end
            else if(switch_cfg.addr == 8'h15) begin
                next_dateline = cfg_data[NUM_OUTPORTS-1:0];
            end
        end
    end

endmodule
