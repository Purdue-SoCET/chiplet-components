`include "uart_rx_if.sv"
`include "uart_tx_if.sv"
`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"

module uart_baud #(
    parameter PORTCOUNT = 5,
    parameter FREQUENCY = 1000000   0,
    parameter EXPECTED_BAUD_RATE = 1000000
)(
    input logic CLK, nRST,
    input[CLKDIV_SIZE]
    uart_rx_if.rx rx_if,
    uart_tx_if.tx tx_if
);
    

    uart_rx #(
        .PORTCOUNT(PORTCOUNT),
        .CLKDIV_COUNT(CLKDIV)
    ) rx (
        .CLK(CLK),
        .nRST(nRST),
        .rx_if(rx_if)
    );

    uart_tx #(
        .PORTCOUNT(PORTCOUNT),
        .CLKDIV_COUNT(CLKDIV)
    ) tx (
        .CLK(CLK),
        .nRST(nRST),
        .tx_if(tx_if)
    );
    logic [31:0] Baud_Rate; 
    always_ff @(posedge CLK, negedge nRST) begin
        
    end
endmodule
