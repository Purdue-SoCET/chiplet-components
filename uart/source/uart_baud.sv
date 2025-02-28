`include "uart_rx_if.sv"
`include "uart_tx_if.sv"
`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"

module uart_baud #(parameter PORTCOUNT =5, parameter FREQUENCY = 10000000, parameter EXPECTED_BAUD_RATE = 1000000)(input logic CLK, nRST,uart_rx_if.rx rx_if, uart_tx_if.tx tx_if );

    parameter CLKDIV = FREQUENCY / EXPECTED_BAUD_RATE;
    uart_rx #(.PORTCOUNT(PORTCOUNT),.CLKDIV_COUNT(CLKDIV))
        rx
        (.CLK(CLK),.nRST(nRST),.rx_if(rx_if));

    uart_tx #(.PORTCOUNT(PORTCOUNT),.CLKDIV_COUNT(CLKDIV))
        tx
         (.CLK(CLK),.nRST(nRST),.tx_if(tx_if));
endmodule
