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

    logic [NUM_OUTPORTS-1:0] next_data_ready_out;
    logic reg_bank_claim;

    // Buffers
    buffers_if #(
        .NUM_BUFFERS(2*NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS),
        .DEPTH(BUFFER_SIZE) // How many flits should each buffer hold
    ) buf_if();

    // Use single buffer to make signal routing easier, internally is split
    // into {vc1, vc0}
    buffers #(
        .NUM_BUFFERS(2*NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .DEPTH(BUFFER_SIZE)
    ) BUFF (
        .CLK(clk),
        .nRST(n_rst),
        .buf_if(buf_if)
    );

    // Connect buffers to IO
    always_comb begin
        buf_if.wdata = '0;
        for (int i = 0; i < NUM_BUFFERS; i++) begin
            if (!sw_if.in[i].vc) begin
                buf_if.WEN[i] = sw_if.data_ready_in[i];
                buf_if.wdata[i] = sw_if.in[i];
            end else begin
                buf_if.WEN[i + NUM_BUFFERS] = sw_if.data_ready_in[i];
                buf_if.wdata[i + NUM_BUFFERS] = sw_if.in[i];
            end

            for (int j = 0; j < NUM_VCS; j++) begin
                sw_if.buffer_available[i][j] = buf_if.available[NUM_BUFFERS*j+i];
            end
        end
    end

    // Stage 1: Route compute
    arbiter_if #(
        .WIDTH(2*NUM_BUFFERS)
    ) rc_a_if();
    route_compute_if #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TABLE_SIZE(32) // TODO: parameterize
    ) rc_if();

    arbiter #(
        .WIDTH(2*NUM_BUFFERS)
    ) RC_ARBITER (
        .CLK(clk),
        .nRST(n_rst),
        .a_if(rc_a_if)
    );
    route_compute #(
        .NODE(NODE),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TOTAL_NODES(TOTAL_NODES)
    ) RC (
        .clk(clk),
        .n_rst(n_rst),
        .route_if(rc_if)
    );

    // Connect buffers to arbiter
    assign rc_a_if.bid = buf_if.req_routing;
    // Connect arbiter to route compute
    assign rc_if.valid = rc_a_if.valid;
    assign rc_if.head_flit = buf_if.rdata[rc_a_if.select];
    assign rc_if.route_lut = rb_if.route_lut;
    assign buf_if.routing_outport = rc_if.out_sel;
    assign buf_if.routing_granted = rc_if.sel_valid << rc_a_if.select;

    // Stage 2: VC allocation
    arbiter_if #(
        .WIDTH(2*NUM_BUFFERS)
    ) vc_a_if();
    vc_allocator_if #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) vc_if();

    arbiter #(
        .WIDTH(2*NUM_BUFFERS)
    ) VCALLOC_ARBITER (
        .CLK(clk),
        .nRST(n_rst),
        .a_if(vc_a_if)
    );
    vc_allocator #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE)
    ) VCALLOC (
        .clk(clk),
        .n_rst(n_rst),
        .vc_if(vc_if)
    );

    // Connect buffers to arbiter
    assign vc_a_if.bid = buf_if.req_vc;
    // Connect buffers to VC allocator
    assign vc_if.incoming_vc = buf_if.rdata[vc_a_if.select].vc;
    assign vc_if.outport = buf_if.switch_outport[vc_a_if.select];
    assign buf_if.vc_selection = vc_if.assigned_vc;
    assign buf_if.vc_granted = vc_a_if.valid << vc_a_if.select;
    // Connect VC allocator to register bank
    assign vc_if.dateline = rb_if.dateline;

    // Stage 3: Switch allocation
    arbiter_if #(
        .WIDTH(2*NUM_BUFFERS)
    ) sa_a_if();
    switch_allocator_if #(
        .NUM_BUFFERS(2*NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS)
    ) sa_if();

    arbiter #(
        .WIDTH(2*NUM_BUFFERS)
    ) SWALLOC_ARBITER (
        .CLK(clk),
        .nRST(n_rst),
        .a_if(sa_a_if)
    );
    switch_allocator #(
        .NUM_BUFFERS(2*NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS)
    ) SWALLOC (
        clk,
        n_rst,
        sa_if
    );

    // Connect buffers to arbiter
    assign sa_a_if.bid = buf_if.req_switch;
    // Connect buffers and arbiter to switch allocator
    assign sa_if.valid = buf_if.req_crossbar;
    assign sa_if.allocate = sa_a_if.valid;
    assign sa_if.requestor = sa_a_if.select;
    assign sa_if.requested = buf_if.switch_outport[sa_a_if.select];
    assign buf_if.switch_granted = sa_if.switch_valid << sa_a_if.select;

    // Stage 4: Crossbar traversal
    crossbar_if #(
         .T(flit_t),
         .NUM_IN(2*NUM_BUFFERS),
         .NUM_OUT(NUM_OUTPORTS),
         .NUM_VCS(NUM_VCS)
    ) cb_if();
    crossbar #(
        .NUM_IN(2*NUM_BUFFERS),
        .NUM_OUT(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE)
    ) CB (
        .clk(clk),
        .n_rst(n_rst),
        .cb_if(cb_if)
    );

    // Connect buffers and switch allocator to crossbar
    always_comb begin
        cb_if.in = buf_if.rdata;
        for (int i = 0; i < NUM_BUFFERS; i++) begin
            cb_if.in[i].vc = buf_if.final_vc[i];
        end
    end
    assign cb_if.sel = sa_if.select;
    assign cb_if.enable = sa_if.enable;
    assign buf_if.REN = cb_if.in_pop;
    // Connect crossbar to IO
    assign cb_if.packet_sent = {sw_if.packet_sent[NUM_OUTPORTS-1:1], sw_if.packet_sent[0] || reg_bank_claim};
    assign cb_if.credit_granted = {sw_if.credit_granted[NUM_OUTPORTS-1:1], sw_if.credit_granted[0] | {NUM_VCS-1{reg_bank_claim}}};
    assign sw_if.out = cb_if.out;

    // Stage 5: Claim things going to this node and forward things to reg bank
    // as necessary
    switch_reg_bank_if #(
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TOTAL_NODES(TOTAL_NODES),
        .TABLE_SIZE(32) // TODO: parameterize
    ) rb_if();

    switch_reg_bank #(
        .NODE(NODE),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TABLE_SIZE(32),
        .TOTAL_NODES(TOTAL_NODES)
    ) REGBANK (
        .clk(clk),
        .n_rst(n_rst),
        .rb_if(rb_if)
    );

    assign reg_bank_claim = sa_if.enable[0] && cb_if.out[0].payload[31:28] == FMT_SWITCH_CFG && cb_if.out[0].payload[27:23] == NODE;
    assign rb_if.in_flit = reg_bank_claim ? cb_if.out[0] : '0;

    assign sw_if.data_ready_out = {cb_if.valid[NUM_OUTPORTS-1:1], cb_if.valid[0] && !reg_bank_claim};
endmodule
