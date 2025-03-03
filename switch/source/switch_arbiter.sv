`include "arbiter_if.sv"

// Round robin arbiter
module switch_arbiter#(
    parameter int WIDTH
)(
    input logic CLK, nRST,
    arbiter_if.arbiter a_if
);
    logic [$clog2(WIDTH)-1:0] next_select;
    logic [WIDTH-1:0] left, right;
    logic found;
    flit_t next_flit;

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            a_if.select <= 0;
            a_if.valid <= 0;
            a_if.flit <= 0;
        end else begin
            a_if.select <= next_select;
            a_if.valid <= found;
            a_if.flit <= next_flit;
        end
    end

    always_comb begin
        next_select = a_if.select;
        left = 0;
        right = 0;
        found = 0;
        next_flit = a_if.flit;

        for (int i = 0; i < WIDTH; i++) begin
            left[i] = i <= a_if.select;
        end
        right = ~left;
        left &= a_if.bid;
        right &= a_if.bid;

        // Current winner has finished request
        if (!a_if.valid) begin
            // Start looking at everything after current requester to find
            // first set
            for (int i = 0; i < WIDTH; i++) begin
                if (!found && right[i]) begin
                    /* verilator lint_off WIDTHTRUNC */
                    next_select = i;
                    next_flit = a_if.rdata[next_select];
                    /* verilator lint_on WIDTHTRUNC */
                    found = 1;
                end
            end

            // Then look for anything to the left (including current
            // selection)
            for (int i = 0; i < WIDTH; i++) begin
                if (!found && left[i]) begin
                    /* verilator lint_off WIDTHTRUNC */
                    next_select = i;
                    next_flit = a_if.rdata[next_select];
                    /* verilator lint_on WIDTHTRUNC */
                    found = 1;
                end
            end
        end
    end
endmodule
