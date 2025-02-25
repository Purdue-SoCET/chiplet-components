// CRC calculator with variable unrolling factor. Initial value and xor out
// are '1 which will change the expected remainder when CRC is appended to
// original message. For example, with CRC32, the expected value is 0x2144DF1C
// not 0x00000000.
module socetlib_crc #(
    parameter int NUM_BITS = 32,
    parameter logic [NUM_BITS-1:0] INIT_VAL = '1,
    parameter logic [NUM_BITS-1:0] POLYNOMIAL = 32'h04C11DB7,
    parameter logic [NUM_BITS-1:0] XOR_OUT = '1,
    parameter int UNROLL_FACTOR = 8
) (
    input logic CLK,
    input logic nRST,
    input logic clear,
    input logic update,
    input logic [NUM_BITS-1:0] in,
    output logic [NUM_BITS-1:0] crc_out,
    output logic done
);
    localparam COUNTER_MAX = NUM_BITS/UNROLL_FACTOR;
    localparam COUNTER_BITS = $clog2(COUNTER_MAX + 1) + (UNROLL_FACTOR == NUM_BITS);

    logic [NUM_BITS-1:0] out;
    logic [COUNTER_BITS-1:0] offset;
    logic [NUM_BITS-1:0] lfsr_in;

    socetlib_lfsr #(
        .NUM_BITS(32),
        .INIT_VAL('1),
        .SHIFT_RIGHT(0),
        .UNROLL_FACTOR(UNROLL_FACTOR)
    ) lfsr (
        .CLK(CLK),
        .nRST(nRST),
        .clear(clear),
        .enable(update),
        .in(in[offset*UNROLL_FACTOR+:UNROLL_FACTOR]),
        .load(0),
        .seed(0),
        .polynomial(POLYNOMIAL),
        .out(out)
    );

    generate
        if (COUNTER_MAX == 1) begin
            assign done = update;
        end else begin
            socetlib_counter #(
                .NBITS(COUNTER_BITS)
            ) counter (
                .CLK(CLK),
                .nRST(nRST),
                .clear(done),
                .count_enable(update),
                .overflow_val(COUNTER_MAX[COUNTER_BITS-1:0]),
                .count_out(offset),
                .overflow_flag(done)
            );
        end
    endgenerate

    assign crc_out = bit_reverse(out) ^ XOR_OUT;

    function logic [NUM_BITS-1:0] bit_reverse(
        input logic [NUM_BITS-1:0] in
    );
        for (int i = 0; i < NUM_BITS; i++) begin
            bit_reverse[i] = in[NUM_BITS - 1 - i];
        end
    endfunction
endmodule
