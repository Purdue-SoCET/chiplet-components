`include "switch_pkg.sv"

module switch_allocator#(
    parameter int NUM_BUFFERS,
    parameter int NUM_OUTPORTS
)(
    input logic clk,
    input logic n_rst,
    switch_allocator_if.allocator sa_if
);
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_BUFFERS) + (NUM_BUFFERS == 1);

    logic [NUM_OUTPORTS-1:0] [SELECT_SIZE-1:0] next_select;
    logic [NUM_OUTPORTS-1:0] next_enable;

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

        // For any new input buffer that requests a output port, arbitrate
        // between them. Lowest buffer wins out
        for (int buffer = 0; buffer < NUM_BUFFERS; buffer++) begin
             /* Buffer is requesting and  Enable isn't set for requested output */
            if (sa_if.allocate[buffer] && !next_enable[sa_if.requested[buffer]]) begin
                next_select[sa_if.requested[buffer]] = buffer[0+:SELECT_SIZE];
                next_enable[sa_if.requested[buffer]] = 1;
            end
        end

        // If any input buffer drops `allocate`, deallocate it.
        for (int outport = 0; outport < NUM_OUTPORTS; outport++) begin
            next_enable[outport] &= sa_if.allocate[sa_if.select[outport]];
        end
    end
endmodule
