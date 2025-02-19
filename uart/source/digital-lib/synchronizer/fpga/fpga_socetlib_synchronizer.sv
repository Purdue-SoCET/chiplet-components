module fpga_socetlib_synchronizer(
    input CLK_50,
    input [3:0] KEY,
    output [8:0] LEDG
);

    socetlib_synchronizer #(
        .RESET_STATE(1'b1),
        .STAGES(3)
    ) SYNC (
        .CLK(CLK_50),
        .nRST(KEY[1]),
        .async_in(KEY[0]),
        .sync_out(LEDG[0])
    );

endmodule
