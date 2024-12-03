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
                .clear(buf_if.clear[i]),
                .wdata(buf_if.wdata[i]),
                .full(buf_if.full[i]),
                .empty(buf_if.empty[i]),
                .overrun(buf_if.overrun[i]),
                .underrun(buf_if.underrun[i]),
                .count(buf_if.count[i]),
                .rdata(buf_if.rdata[i])
            );

            socetlib_counter #(
                .NBITS(PKT_LENGTH_WIDTH)
            ) PACKET_COUNTER (
                .CLK(CLK),
                .nRST(nRST),
                .clear(overflow[i]),
                .count_enable(buf_if.WEN[i]),
                .overflow_val(overflow_val[i]),
                .count_out(),
                .overflow_flag(overflow[i])
            );
        end
    endgenerate

    always_comb begin
        next_valid = buf_if.valid;
        next_overflow_val = overflow_val;

        for (int j = 0; j < NUM_BUFFERS; j++) begin
            if (!overflow[j]) begin
                next_valid[j] = 0;
            end if (buf_if.WEN[j] || buf_if.count[j] > 0) begin
                next_valid[j] = 1;
            end

            // Head flit condition
            if (buf_if.WEN[j] && buf_if.count[j] == 0) begin
                next_overflow_val[j] = expected_num_flits(buf_if.wdata[j].payload);
            end else if (buf_if.count > 0) begin
                next_overflow_val[j] = expected_num_flits(buf_if.rdata[j].payload);
            end
        end
    end
endmodule
