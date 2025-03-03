module fpga_endnode_wrapper(
    input logic CLOCK_50,
    input logic [3:0] KEY
);
    endnode_if end_if();

    endnode endp (
        .CLK(CLOCK_50),
        .nRST(!KEY[0]),
        .end_if(end_if)
    );
endmodule
