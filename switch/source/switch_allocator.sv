`include "switch_pkg.sv"
`include "pipeline_if.sv"
`include "switch_allocator_if.sv"

module switch_allocator#(
    parameter int NUM_BUFFERS,
    parameter int NUM_OUTPORTS,
    parameter int NUM_VCS
)(
    input logic clk,
    input logic n_rst,
    pipeline_if.sa pipe_if,
    switch_allocator_if.allocator sa_if
);
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_BUFFERS) + (NUM_BUFFERS == 1);

    logic alloc_success, speculative_success, next_speculative_success;
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] [SELECT_SIZE-1:0] next_select;
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] next_enable;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            pipe_if.pipe_valid <= 0;
            pipe_if.pipe_ingress_port <= 0;
            pipe_if.pipe_vc <= 0;
            pipe_if.pipe_failed <= 0;
            sa_if.select <= '0;
            sa_if.enable <= '0;
            speculative_success <= '0;
        end else begin
            pipe_if.pipe_valid <= pipe_if.sa_valid;
            pipe_if.pipe_ingress_port <= pipe_if.sa_ingress_port;
            pipe_if.pipe_vc <= pipe_if.sa_final_vc;
            pipe_if.pipe_failed <= !alloc_success;
            sa_if.select <= next_select;
            sa_if.enable <= next_enable;
            speculative_success <= next_speculative_success;
        end
    end

    always_comb begin
        next_select = sa_if.select;
        next_enable = sa_if.enable;
        alloc_success = 0;
        next_speculative_success = 0;

        // If any input buffer drops `valid`, deallocate it.
        for (int outport = 0; outport < NUM_OUTPORTS; outport++) begin
            for (int vc = 0; vc < NUM_VCS; vc++) begin
                next_enable[outport][vc] &= sa_if.valid[sa_if.select[outport][vc]];
            end
        end

        // If a buffer requests allocation and the outport hasn't been
        // allocated yet, allow the allocation
        if (pipe_if.sa_valid && !sa_if.enable[pipe_if.sa_egress_port][pipe_if.sa_final_vc]) begin
            next_select[pipe_if.sa_egress_port][pipe_if.sa_final_vc] = pipe_if.sa_ingress_port;
            next_enable[pipe_if.sa_egress_port][pipe_if.sa_final_vc] = 1'b1;
            alloc_success = 1;
        end

        // After we enable allocation of the thing actually in SA, lets
        // speculatively try to allocate whatevers in VC
        if (pipe_if.vc_valid && !(|(sa_if.enable[pipe_if.vc_egress_port] | next_enable[pipe_if.vc_egress_port]))) begin
            next_select[pipe_if.vc_egress_port] = {NUM_VCS{pipe_if.vc_ingress_port}};
            next_enable[pipe_if.vc_egress_port] = {NUM_VCS{1'b1}};
            next_speculative_success = 1;
        end

        if (speculative_success) begin
            next_enable[pipe_if.sa_egress_port] = 1'b1 << pipe_if.sa_final_vc;
            alloc_success = 1;
        end
    end
endmodule
