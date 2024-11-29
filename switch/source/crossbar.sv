// Creates a M input to N output crossbar switch of data type T.
// This design updates synchronously updates output ports

`include "crossbar_if.sv"

module crossbar#(
    parameter type T,
    parameter T RESET_VAL,
    parameter int NUM_OUT
)(
    input logic clk, n_rst,
    crossbar_if.crossbar cb_if
);
    T [NUM_OUT-1:0] next_out;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            cb_if.out <= {NUM_OUT{RESET_VAL}};
        end else begin
            cb_if.out <= next_out;
        end
    end

    always_comb begin
        for (int i = 0; i < NUM_OUT; i++) begin
            if (!cb_if.enable[i]) begin
                next_out[i] = '0;
            end else begin
                next_out[i] = cb_if.in[cb_if.sel[i]];
            end
        end
    end
endmodule
