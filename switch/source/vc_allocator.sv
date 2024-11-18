`include "vc_allocator_if.sv"

module vc_allocator#(
    parameter int NUM_OUTPORTS,
    parameter int NUM_BUFFERS,
    parameter int NUM_VCS,
    parameter int BUFFER_SIZE /* Buffer size in words */
)(
    input logic clk,
    input logic n_rst,
    vc_allocator_if.allocator vc_if
);
    // Static limit of 3/4 the total buffer capacity
    localparam int FULL_LIMIT = BUFFER_SIZE/2 + BUFFER_SIZE/4;

    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] [$clog2(BUFFER_SIZE+1)-1:0] buffer_availability, next_buffer_availability;
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] next_buffer_available;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            vc_if.buffer_available <= '1;
            buffer_availability <= '{default: BUFFER_SIZE};
        end else begin
            vc_if.buffer_available <= next_buffer_available;
            buffer_availability <= next_buffer_availability;
        end
    end

    always_comb begin
        next_buffer_available = vc_if.buffer_available;
        next_buffer_availability = buffer_availability;

        for (int i = 0; i < NUM_BUFFERS; i++) begin
            vc_if.assigned_vc[i] = vc_if.incoming_vc[i] + vc_if.dateline[i];
        end

        for (int i = 0; i < NUM_BUFFERS; i++) begin
            for (int j = 0; j < NUM_VCS; j++) begin
                next_buffer_availability[i][j] = buffer_availability[i][j] -
                    vc_if.packet_sent[i][j] + vc_if.credit_granted[i][j];
            end
        end

        for (int i = 0; i < NUM_BUFFERS; i++) begin
            for (int j = 0; j < NUM_VCS; j++) begin
                next_buffer_available[i][j] = buffer_availability[i][j] < FULL_LIMIT;
            end
        end
    end
endmodule
