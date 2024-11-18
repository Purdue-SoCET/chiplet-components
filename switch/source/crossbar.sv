// Creates a M input to N output crossbar switch of data type T.
// This design updates synchronously updates output ports
module crossbar#(
    parameter type T,
    parameter T RESET_VAL,
    parameter int M,
    parameter int N
)(
    input logic clk, n_rst,
    crossbar_if.crossbar cb_if
);
    T [N-1:0] next_out;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            cb_if.out <= {N{RESET_VAL}};
        end else begin
            cb_if.out <= next_out;
        end
    end

    always_comb begin
        for (int i = 0; i < N; i++) begin
            next_out[i] = cb_if.in[cb_if.sel[i]];
        end
    end
endmodule
