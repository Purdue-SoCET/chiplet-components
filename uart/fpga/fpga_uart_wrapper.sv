module fpga_uart_wrapper(
    input logic CLOCK_50,
    input logic [3:0] KEY
);
    uart_rx_if rx_if();
    uart_tx_if tx_if();

    uart_baud uart (
        .CLK(CLOCK_50),
        .nRST(!KEY[0]),
        .rx_if(rx_if),
        .tx_if(tx_if)
    );
endmodule
