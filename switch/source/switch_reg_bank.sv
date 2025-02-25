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

    localparam LUT_TOP_ADDR = 8'h10;
    localparam DATELINE_ADDR = 8'h11;
    localparam NODE_ID_ADDR = 8'h12;

    switch_cfg_hdr_t switch_cfg;
    logic [14:0] cfg_data;

    route_lut_t [TABLE_SIZE-1:0] next_route_lut;
    logic [NUM_OUTPORTS-1:0] next_dateline;
    node_id_t next_node_id;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            rb_if.dateline <= '0;
            rb_if.route_lut <= '0;
            rb_if.node_id <= '0;
        end else begin
            rb_if.dateline <= next_dateline;
            rb_if.route_lut <= next_route_lut;
            rb_if.node_id <= next_node_id;
        end
    end

    always_comb begin
        next_dateline = rb_if.dateline;
        next_route_lut = rb_if.route_lut;
        next_node_id = node_id;

        switch_cfg = switch_cfg_hdr_t'(rb_if.in_flit.payload);
        cfg_data = {switch_cfg.data_hi, switch_cfg.data_lo};

        if(switch_cfg.format == FMT_SWITCH_CFG) begin
            if(switch_cfg.addr <= LUT_TOP_ADDR) begin
                next_route_lut[switch_cfg.addr] = route_lut_t'(cfg_data);
            end else if(switch_cfg.addr == DATELINE_ADDR) begin
                next_dateline = cfg_data[NUM_OUTPORTS-1:0];
            end else if(switch_cfg.addr == NODE_ID_ADDR) begin
                next_node_id = cfg_data[4:0];
            end
        end
    end

endmodule
