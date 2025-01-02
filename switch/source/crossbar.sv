// Creates a M input to N output crossbar switch of data type T.
// This design updates synchronously updates output ports

`include "crossbar_if.sv"

module crossbar#(
    parameter type T,
    parameter T RESET_VAL,
    parameter int NUM_IN,
    parameter int NUM_OUT
)(
    input logic clk, n_rst,
    crossbar_if.crossbar cb_if
);
    T [NUM_OUT-1:0] next_out;
    logic [NUM_OUT-1:0] valid, next_valid;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            cb_if.out <= {NUM_OUT{RESET_VAL}};
            valid <= '0;
        end else begin
            cb_if.out <= next_out;
            valid <= next_valid;
        end
    end

    assign cb_if.valid = valid & cb_if.enable;

    always_comb begin
        cb_if.in_pop = '0;
        next_valid = cb_if.valid;
        for (int i = 0; i < NUM_OUT; i++) begin
            if (!cb_if.enable[i]) begin
                next_out[i] = '0;
            end else begin
                next_out[i] = cb_if.in[cb_if.sel[i]];
                next_valid[i] = 1;
                if (cb_if.packet_sent[i]) next_valid[i] = 0;
                cb_if.in_pop[cb_if.sel[i]] = cb_if.packet_sent[i];
            end
        end
    end
endmodule
