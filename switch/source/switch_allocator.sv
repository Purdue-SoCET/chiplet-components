`include "switch_pkg.sv"

module switch_allocator#(
    parameter int NUM_BUFFERS,
    parameter int NUM_OUTPORTS,
    parameter int NUM_VCS
)(
    input logic clk,
    input logic n_rst,
    switch_allocator_if.allocator sa_if
);
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_BUFFERS) + (NUM_BUFFERS == 1);

    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] [SELECT_SIZE-1:0] next_select;
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] next_enable;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            sa_if.select <= '0;
            sa_if.enable <= '0;
        end else begin
            sa_if.select <= next_select;
            sa_if.enable <= next_enable;
        end
    end

    always_comb begin
        next_select = sa_if.select;
        next_enable = sa_if.enable;
        sa_if.switch_valid = 0;

        // If a buffer requests allocation and the outport hasn't been
        // allocated yet, allow the allocation
        if (sa_if.allocate && !sa_if.enable[sa_if.requested][sa_if.requested_vc]) begin
            next_select[sa_if.requested][sa_if.requested_vc] = sa_if.requestor;
            next_enable[sa_if.requested][sa_if.requested_vc] = 1;
            sa_if.switch_valid = 1;
        end

        // If any input buffer drops `valid`, deallocate it.
        for (int outport = 0; outport < NUM_OUTPORTS; outport++) begin
            for (int vc = 0; vc < NUM_VCS; vc++) begin
                next_enable[outport][vc] &= sa_if.valid[sa_if.select[outport][vc]];
            end
        end
    end
endmodule
