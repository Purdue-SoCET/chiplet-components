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
        .DEPTH(BUFFER_SIZE) // How many flits should each buffer hold
    ) buf_if;

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
        .DEPTH(BUFFER_SIZE)
    ) BUFFS(
        clk,
        n_rst, 
        buf_if
    );

    logic [NUM_BUFFERS-1:0] [BUFFER_BITS-1:0] buffs, next_buffs;
    flit_t [NUM_BUFFERS-1:0] next_in_flit;

    assign sa_if.requested = rc_if.out_sel;
    assign sa_if.allocate = rc_if.allocate;

    //assign rc_if.buffer_sel = 
    assign rc_if.route_lut = rb_if.route_lut;
    
    assign cb_if.sel = sa_if.select;
    assign cb_if.enable = sa_if.enable;

    assign sw_if.out = cb_if.out;
    assign sw_if.buffer_available = vc_if.buffer_available;

    assign vc_if.credit_granted = sw_if.credit_granted;
    assign vc_if.packet_sent = sw_if.packet_sent;
    assign vc_if.dateline = rb_if.dateline;

    int k;
    pkt_id_t [NUM_BUFFERS-1:0] id1, next_id1;
    node_id_t [NUM_BUFFERS-1:0] req1, next_req1;
    logic [NUM_OUTPORTS-1:0] next_data_ready_out;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            buffs <= '0;
            id1 <= '0;
            req1 <= '0;
            sw_if.data_ready_out <= '0;
        end else begin
            buffs <= next_buffs;
            id1 <= next_id1;
            req1 <= next_req1;
            sw_if.data_ready_out <= next_data_ready_out;
        end
    end

    //TODO init virtual channels
    //TODO flush packet from buffer after its sent
    always_comb begin
        // next_buffs = buffs;
        // for(int i = 0; i < NUM_BUFFERS; i++) begin
        //     if(sw_if.data_ready_in[i]) begin
        //         next_buffs[i] = sw_if.in[i];
        //     end
        // end
        next_data_ready_out = sa_if.enable;
    end

    always_comb begin
        for(k = 0; k < NUM_BUFFERS; k++) begin
            next_id1[k] = sw_if.in[k].id;
            next_req1[k] = sw_if.in[k].req;
        end

        // TODO: should make buffers FIFOs and just store head flits
        // TODO: should also move this to separate module
        rc_if.in_flit = '0;
        rb_if.in_flit = '0;
        for(int j = 0; j < NUM_BUFFERS; j++) begin
            if(sw_if.data_ready_in[j]) begin
                if(id1[j] != sw_if.in[j].id || req1[j] != sw_if.in[k].req) begin
                    rc_if.in_flit[j] = sw_if.in[j];
                    rb_if.in_flit[j] = sw_if.in[j];
                end
            end
        end
    end
endmodule
