`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_if.vh"

module switch #(
    parameter int NUM_LINKS,
    parameter int NUM_VCS,
    parameter int BUFFER_SIZE,
    parameter int TOTAL_NODES,
    parameter node_id_t NODE,
) (
    input logic clk, n_rst,
    switch_if.switch sw_if
);
    parameter int BUFFER_BITS = BUFFER_SIZE * 8;
    parameter int NUM_BUFFERS = NUM_LINKS + 1;
    parameter int NUM_OUTPORTS = NUM_LINKS + 1;
    parameter flit_t RESET_VAL = '0;

    vc_allocator_if.allocator #(
        .NUM_BUFFERS(NUM_BUFFERS), 
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) vc_if;
    route_compute_if.route #(
        .NUM_BUFFERS(NUM_BUFFERS), 
        .NUM_OUTPORTS(NUM_OUTPORTS)
    ) rc_if;
    crossbar_if.crossbar #(
         .T(flit_t),
         .M(NUM_BUFFERS),
         .N(NUM_OUTPORTS)
    ) cb_if;
    switch_allocator_if.allocator #(
        .NUM_BUFFERS(NUM_BUFFERS), 
        .NUM_OUTPORTS(NUM_OUTPORTS)
    ) sa_if;

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
        .TOTAL_NODES(TOTAL_NODES)
    ) ROUTECOMP(
        clk, 
        n_rst, 
        rc_if
    );
    crossbar #(
        .T(flit_t),
        .RESET_VAL(RESET_VAL),
        .N(NUM_OUTPORTS)
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

    logic [BUFFER_BITS-1:0] buffs [NUM_BUFFERS-1:0];
    logic [BUFFER_BITS-1:0] next_buffs [NUM_BUFFERS-1:0];

    assign sa_if.requested = rc_if.out_sel;
    assign sa_if.allocate = rc_if.allocate;

    //assign rc_if.buffer_sel = 
    
    assign cb_if.sel = sa_if.select;
    assign cb_if.enable = sa_if.enable;

    assign sw_if.out = cb_if.out;
    assign sw_if.buffer_available = vc_if.buffer_available;
    assign sw_if.data_ready_out = sa_if.enable;

    assign vc_if.credit_granted = sw_if.credit_granted;

    int k;
    pkt_id_t [NUM_BUFFERS-1:0] id1, next_id1;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            buffs <= '0;
            id1 <= '0;
        end else begin
            buffs <= next_buffs;
            
            id1 <= next_id1;
        end
    end

    //TODO init virtual channels
    //TODO flush packet from buffer after its sent
    always_comb begin
        next_buffs = buffs;
        for(int i = 0; i < NUM_BUFFERS, i++) begin
            if(sw_if.data_ready_in[i]) begin
                next_buffs[i] = sw_if.in[i];
            end
        end
    end
    //TODO get head flit of each packet going into a buffer to route compute
    always_comb begin
        for(k = 0; k < NUM_BUFFERS; k++) begin
                next_id1[k] = sw_if.in[k].id;
        end

        for(int j = 0; j < NUM_BUFFERS, j++) begin
            if(sw_if.data_ready_in[i]) begin
                if(id1 != sw_if.in.id) begin
                    rc_if.in_flit[i] = sw_if.in[i];
                end
            end
        end
    end

    //buffer select signal in route compute?
    //checking data ready when checking id change?

endmodule