`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_if.vh"
`include "switch_reg_bank_if.sv"

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
    // Interfaces
    pipeline_if #(
        .NUM_BUFFERS(2*NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) pipe_if();
    buffers_if #(
        .NUM_BUFFERS(2*NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS),
        .DEPTH(BUFFER_SIZE) // How many flits should each buffer hold
    ) buf_if();
    arbiter_if #(
        .WIDTH(2*NUM_BUFFERS)
    ) rc_a_if();
    switch_allocator_if #(
        .NUM_BUFFERS(2*NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) sa_if();
    crossbar_if #(
         .NUM_IN(2*NUM_BUFFERS),
         .NUM_OUT(NUM_OUTPORTS),
         .NUM_VCS(NUM_VCS)
    ) cb_if();
    switch_reg_bank_if #(
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .TOTAL_NODES(TOTAL_NODES),
        .TABLE_SIZE(32) // TODO: parameterize
    ) rb_if();

    // Buffers
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
        buf_if.WEN = '0;
        for (int i = 0; i < NUM_BUFFERS; i++) begin
            if (!sw_if.in[i].metadata.vc) begin
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
    assign buf_if.pipeline_failed = (pipe_if.pipe_valid && pipe_if.pipe_failed) << pipe_if.pipe_ingress_port;

    // Stage 1: Route compute
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
        .pipe_if(pipe_if),
        .rb_if(rb_if)
    );

    always_comb begin
        // Connect buffers to arbiter
        rc_a_if.bid = buf_if.req_pipeline;
        // Connect arbiter to route compute
        pipe_if.rc_valid = rc_a_if.valid;
        pipe_if.rc_metadata = buf_if.rdata[rc_a_if.select].metadata;
        pipe_if.rc_dest = buf_if.rdata[rc_a_if.select].payload[27:23];
        pipe_if.rc_ingress_port = rc_a_if.select;
        buf_if.pipeline_granted = rc_a_if.valid << rc_a_if.select;
        // Connect switch allocator to register bank
        rb_if.reg_bank_claim = pipe_if.rc_valid &&
            buf_if.rdata[pipe_if.rc_ingress_port].payload[31:28] == FMT_SWITCH_CFG &&
            buf_if.rdata[pipe_if.rc_ingress_port].payload[27:23] == NODE;
        rb_if.in_flit = rb_if.reg_bank_claim ? buf_if.rdata[pipe_if.rc_ingress_port] : '0;
        buf_if.reg_bank_granted = rb_if.reg_bank_claim << pipe_if.rc_ingress_port;
    end

    // Stage 2: VC allocation
    vc_allocator #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE)
    ) VCALLOC (
        .clk(clk),
        .n_rst(n_rst),
        .pipe_if(pipe_if),
        .rb_if(rb_if)
    );

    // Connect VC allocator to buffer
    assign buf_if.final_vc = pipe_if.sa_final_vc;
    assign buf_if.vc_granted = pipe_if.sa_valid << pipe_if.sa_ingress_port;

    // Stage 3: Switch allocation
    switch_allocator #(
        .NUM_BUFFERS(2*NUM_BUFFERS),
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) SWALLOC (
        .clk(clk),
        .n_rst(n_rst),
        .pipe_if(pipe_if),
        .sa_if(sa_if)
    );

    // Connect buffers and arbiter to switch allocator
    assign sa_if.valid = buf_if.active;

    // Stage 4: Crossbar traversal
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
    assign cb_if.in = buf_if.rdata;
    assign cb_if.sel = sa_if.select;
    assign cb_if.enable = sa_if.enable;
    assign cb_if.empty = buf_if.empty;
    assign cb_if.buffer_vc = buf_if.buffer_vc;
    assign buf_if.REN = cb_if.in_pop;
    // Connect crossbar to IO
    assign cb_if.packet_sent = sw_if.packet_sent[NUM_OUTPORTS-1:0];
    assign cb_if.credit_granted = sw_if.credit_granted[NUM_OUTPORTS-1:0];
    assign sw_if.out = cb_if.out;
    assign sw_if.data_ready_out = cb_if.valid;

    // Stage 5: Claim things going to this node and forward things to reg bank
    // as necessary
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
endmodule
