module switch_arbiter_wrapper(
    input logic CLK, nRST,
    input logic [7:0] bid,
    output logic valid,
    output logic [2:0] select
);
    arbiter_if #(.WIDTH(8)) arbiter_if();
    switch_arbiter #(
        .WIDTH(8)
    ) arbiter (
        .CLK(CLK),
        .nRST(nRST),
        .a_if(arbiter_if)
    );

    assign arbiter_if.bid = bid;
    assign arbiter_if.rdata = 0;
    assign valid = arbiter_if.valid;
    assign select = arbiter_if.select;
endmodule
