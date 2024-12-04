`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "buffers_if.sv"

module buffers #(
    parameter NUM_BUFFERS,
    parameter DEPTH// # of FIFO entries
)(
    input CLK,
    input nRST,
    buffers_if.buffs buf_if
);
    import chiplet_types_pkg::*;

    logic [NUM_BUFFERS-1:0] next_valid;
    logic [NUM_BUFFERS-1:0] overflow;
    logic [NUM_BUFFERS-1:0] [PKT_LENGTH_WIDTH-1:0] overflow_val, next_overflow_val;
    logic [NUM_BUFFERS-1:0] [PKT_LENGTH_WIDTH-1:0] count;

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            buf_if.valid <= '0;
            overflow_val <= '0;
        end else begin
            buf_if.valid <= next_valid;
            overflow_val <= next_overflow_val;
        end
    end

    genvar i;
    generate
        for (i = 0; i < NUM_BUFFERS; i++) begin
            socetlib_fifo #(
                .T(flit_t),
                .DEPTH(DEPTH)
            ) FIFO (
                .CLK(CLK),
                .nRST(nRST),
                .WEN(buf_if.WEN[i]),
                .REN(buf_if.REN[i]),
                .clear(1'b0),
                .wdata(buf_if.wdata[i]),
                .full(),
                .empty(),
                .overrun(),
                .underrun(),
                .count(),
                .rdata(buf_if.rdata[i])
            );

            socetlib_counter #(
                .NBITS(PKT_LENGTH_WIDTH)
            ) PACKET_COUNTER (
                .CLK(CLK),
                .nRST(nRST),
                .clear(!buf_if.valid[i]),
                .count_enable(buf_if.WEN[i]),
                .overflow_val(overflow_val[i]),
                .count_out(count[i]),
                .overflow_flag(overflow[i])
            );
        end
    endgenerate

    always_comb begin
        next_valid = buf_if.valid;
        next_overflow_val = overflow_val;

        for (int j = 0; j < NUM_BUFFERS; j++) begin
            if (buf_if.REN[j] && (overflow[j] || overflow_val[j] == 0)) begin
                next_valid[j] = 0;
            end else if (buf_if.WEN[j] || count[j] > 0) begin
                next_valid[j] = 1;
            end

            // Head flit condition
            // TODO: weird hack to get overflows working properly, any better
            // solutions?
            if (buf_if.WEN[j] && count[j] == 0) begin
                next_overflow_val[j] = expected_num_flits(buf_if.wdata[j].payload) - 1;
            end else if (count > 0) begin
                next_overflow_val[j] = expected_num_flits(buf_if.rdata[j].payload) - 1;
            end
        end
    end
endmodule
