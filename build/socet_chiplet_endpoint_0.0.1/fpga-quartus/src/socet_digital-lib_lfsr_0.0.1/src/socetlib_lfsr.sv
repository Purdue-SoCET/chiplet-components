module socetlib_lfsr #(
    parameter int NUM_BITS = 4,
    parameter logic [NUM_BITS-1:0] INIT_VAL = 0,
    parameter logic SHIFT_RIGHT = 1,
    parameter logic GALOIS = 1,
    parameter int UNROLL_FACTOR = 1
) (
    input logic CLK,
    input logic nRST,
    input logic clear,
    input logic enable,
    input logic [UNROLL_FACTOR-1:0] in,
    input logic load,
    input logic [NUM_BITS-1:0] seed,
    input logic [NUM_BITS-1:0] polynomial,
    output logic [NUM_BITS-1:0] out 
);
    logic [NUM_BITS-1:0] next_out;
    logic shifted_out;

    generate
        if (UNROLL_FACTOR == 0) begin
            $error("UNROLL_FACTOR cannot be 0!");
        end
        if ((UNROLL_FACTOR & (UNROLL_FACTOR - 1)) != 0) begin
            $error("UNROLL_FACTOR must be a power of 2!");
        end
        if (UNROLL_FACTOR > NUM_BITS) begin
            $error("UNROLL_FACTOR cannot be greater than NUM_BITS!");
        end
    endgenerate

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            out <= INIT_VAL;
        end else begin
            out <= next_out;
        end
    end

    logic data_bit;

    always_comb begin
        next_out = out;
        shifted_out = 0;
        data_bit = 0;

        if (clear) begin
            next_out = INIT_VAL;
        end else if (load) begin
            next_out = seed;
        end else if (enable) begin
            for (int i = 0; i < UNROLL_FACTOR; i++) begin
                if (GALOIS) begin
                    data_bit = in[i];
                    if (SHIFT_RIGHT) begin
                        shifted_out = next_out[0];
                        next_out = next_out >> 1;
                    end else begin
                        shifted_out = next_out[NUM_BITS-1];
                        next_out = next_out << 1;
                    end

                    if (shifted_out ^ data_bit) begin
                        next_out ^= polynomial;
                    end
                end else begin
                    shifted_out = ^(next_out & polynomial);

                    if (SHIFT_RIGHT) begin
                        next_out = {shifted_out, next_out[NUM_BITS-1:1]};
                    end else begin
                        next_out = {next_out[NUM_BITS-2:0], shifted_out};
                    end
                end
            end
        end
    end
endmodule
