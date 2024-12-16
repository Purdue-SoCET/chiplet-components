`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_if.vh"

import chiplet_types_pkg::*;

module switch #(
    parameter int NUM_OUTPORTS,
    parameter int NUM_BUFFERS,
    parameter int NUM_VCS,
    parameter int BUFFER_SIZE,
    parameter int TOTAL_NODES,
    parameter node_id_t NODE
) (
    input logic clk, n_rst,
    switch_if.switch sw_if
);
    parameter int BUFFER_BITS = BUFFER_SIZE * 32;
    parameter flit_t RESET_VAL = '0;

    // Interface Declarations
    vc_allocator_if #(
        .NUM_BUFFERS(NUM_BUFFERS), 
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) vc_if();
    route_compute_if #(
        .NUM_BUFFERS(NUM_BUFFERS), 
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TABLE_SIZE(32) // TODO: parameterize
    ) rc_if();
    crossbar_if #(
         .T(flit_t),
         .NUM_IN(NUM_BUFFERS),
         .NUM_OUT(NUM_OUTPORTS)
    ) cb_if();
    switch_allocator_if #(
        .NUM_BUFFERS(NUM_BUFFERS), 
        .NUM_OUTPORTS(NUM_OUTPORTS)
    ) sa_if();
    switch_reg_bank_if #(
        .NUM_BUFFERS(NUM_BUFFERS), 
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TOTAL_NODES(TOTAL_NODES),
        .TABLE_SIZE(32) // TODO: parameterize
    ) rb_if();
    buffers_if #(
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS),
        .DEPTH(BUFFER_SIZE) // How many flits should each buffer hold
    ) buf_if();
    buffers_if #(
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS),
        .DEPTH(BUFFER_SIZE) // How many flits should each buffer hold
    ) vc_buf_if();

    // Module Declarations

    vc_allocator #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE)
    ) VCALLOC(
        clk, 
        n_rst, 
        vc_if
    );
    route_compute #(
        .NODE(NODE),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TOTAL_NODES(TOTAL_NODES)
    ) ROUTECOMP(
        clk, 
        n_rst, 
        rc_if
    );
    crossbar #(
        .T(flit_t),
        .RESET_VAL(RESET_VAL),
        .NUM_IN(NUM_BUFFERS),
        .NUM_OUT(NUM_OUTPORTS)
    ) CROSS(
        clk, 
        n_rst, 
        cb_if
    );
    switch_allocator #(
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS)
    ) SWALLOC(
        clk, 
        n_rst, 
        sa_if
    );
    switch_reg_bank #(
        .NODE(NODE),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TABLE_SIZE(32),
        .TOTAL_NODES(TOTAL_NODES)
    ) REGBANK(
        clk, 
        n_rst,
        rb_if
    );
    buffers #(
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .DEPTH(BUFFER_SIZE)
    ) BUFF1(
        clk,
        n_rst, 
        buf_if
    );
    buffers #(
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .DEPTH(BUFFER_SIZE)
    ) VC1(
        clk,
        n_rst, 
        vc_buf_if
    );
    
    logic [NUM_OUTPORTS-1:0] next_data_ready_out;
    logic [NUM_BUFFERS-1:0] vc_sel, next_vc_sel; //size could be parameterized in the future
    logic reg_bank_claim, next_reg_bank_claim;

    assign sa_if.requested = rc_if.out_sel;
    assign sa_if.allocate = rc_if.allocate;

    assign rc_if.route_lut = rb_if.route_lut;
    assign rc_if.valid = '1;

    assign cb_if.sel = sa_if.select;
    assign cb_if.enable = sa_if.enable;
    assign cb_if.packet_sent = sw_if.packet_sent;
    assign cb_if.packet_sent = {sw_if.packet_sent[NUM_OUTPORTS-1:1], sw_if.packet_sent[0] || reg_bank_claim};

    assign sw_if.out = cb_if.out;
    assign sw_if.buffer_available = vc_if.buffer_available;

    assign vc_if.credit_granted = sw_if.credit_granted;
    assign vc_if.packet_sent = sw_if.packet_sent;
    assign vc_if.dateline = rb_if.dateline;

    assign buf_if.wdata = sw_if.in;
    assign vc_buf_if.wdata = sw_if.in;

    assign next_data_ready_out = {sa_if.enable[NUM_OUTPORTS-1:1], sa_if.enable[0] & !(next_reg_bank_claim || reg_bank_claim)};

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            sw_if.data_ready_out <= '0;
            vc_sel <= '0;
            reg_bank_claim <= 0;
        end else begin
            sw_if.data_ready_out <= next_data_ready_out;
            vc_sel <= next_vc_sel;
            reg_bank_claim <= next_reg_bank_claim;
        end
    end

    always_comb begin //Buffer vs VC arbitration
        buf_if.WEN = '0;
        buf_if.REN = '0;
        vc_buf_if.WEN = '0;
        vc_buf_if.REN = '0;
        next_vc_sel = vc_sel;
        rc_if.in_flit = '0;
        rb_if.in_flit = '0;
        vc_if.incoming_vc = '0;
        next_reg_bank_claim = 0;

        for (int i = 0; i < NUM_BUFFERS; i++) begin
            // TODO: It's actually safe to switch between sending packets on
            // different vcs as long as output vc is different
            if (!vc_sel[i]) begin
                // next_vc_sel[i] = vc_buf_if.valid[i];
            end else if (!vc_sel[i]) begin
                // next_vc_sel[i] = buf_if.valid[i];
            end

            // TODO: read enable needs to come from outport select and packet
            // sent
            if (!sw_if.in[i].vc) begin
                buf_if.WEN[i] = sw_if.data_ready_in[i];
                buf_if.wdata[i] = sw_if.in[i];
            end else begin
                vc_buf_if.WEN[i] = sw_if.data_ready_in[i];
                vc_buf_if.wdata[i] = sw_if.in[i];
            end

            if (vc_sel[i]) begin
                cb_if.in[i] = vc_buf_if.rdata[i];
                rc_if.in_flit[i] = vc_buf_if.rdata[i];
                vc_if.incoming_vc[i] = vc_buf_if.rdata[i].vc;
                // vc_buf_if.REN[i] = vc_buf_if.valid[i] && cb_if.in_pop[i];
            end else begin
                cb_if.in[i] = buf_if.rdata[i];
                rc_if.in_flit[i] = buf_if.rdata[i];
                vc_if.incoming_vc[i] = buf_if.rdata[i].vc;
                buf_if.REN[i] = cb_if.in_pop[i];
            end
        end

        next_reg_bank_claim = sa_if.enable[0] && cb_if.in[0].payload[31:28] == FMT_SWITCH_CFG && cb_if.in[0].payload[27:23] == NODE;

        // Send switch config packets to register bank
        rb_if.in_flit = reg_bank_claim ? cb_if.out[0] : '0;
        // Send everything else outside
        sw_if.out = cb_if.out;
        sw_if.out[0] = reg_bank_claim ? '0 : cb_if.out[0];
    end
endmodule
