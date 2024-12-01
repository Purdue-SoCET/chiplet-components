`timescale 1ns / 10ps

module endnode #( parameter PORTCOUNT = 5, parameter EXPECTED_BAUDRATE = 1000000,

) (
    input logic CLK, nRST, endnode_if.eif end_if
);

    wrap_enc_8b_10b_if phy_tx_if();
    phy_manager_rx_if phy_rx_if();
    uart_rx_if uart_rx_if();
    uart_tx_if uart_tx_if();

    phy_manager_tx #(.PORTCOUNT(PORTCOUNT)) phy_tx 
        (.CLK(CLK),
         .nRST(nRST),
         .wrap_enc_8b_10b_if(enc_if));
    
    phy_manager_rx #(.PORTCOUNT(PORTCOUNT)) phy_rx
        (.CLK(CLK),
        .nRST(nRST),
        .phy_manager_rx_if(phy_rx));

    uart_baud #(.PORTCOUNT(PORTCOUNT),.FREQUENCY(FREQUENCY),.EXPECTED_BAUD_RATE(EXPECTED_BAUD_RATE))
        (.CLK(CLK),
        .nRST(nRST),
        .uart_rx_if(uart_rx_if),
        .uart_tx_if(uart_tx_if));

    //uart_rx_connection
    assign uart_rx_if.uart_in = end_if.uart_rx_in; 
    //rx phy connection
    assign phy_rx_if.enc_flit_rx = uart_rx_if.data;
    assign phy_rx_if.done_uart_rx =uart_rx_if.done;
    assign phy_rx_if.comma_length_sel_rx =uart_rx_if.comma_sel;
    assign phy_rx_if.uart_err_rx = uart_rx_if.rx_err;

    //rx to switch connections
    assign end_if.comma_sel_rx = phy_rx_if.comma_sel;
    assign end_if.done_rx = phy_rx_if.done_out;
    assign end_if.err_rx = phy_rx_if.err_out;
    assign end_if.crc_corr_rx = phy_rx_if.crc_corr;
    assign end_if.flit_rx = phy_rx_if.flit;
    //phy rx to tx
    
    //uart_tx connections
    assign uart_tx_if.data = phy_tx_if.flit_out;
    assign uart_tx_if.start = phy_tx_if.start_out;
    assign uart_tx_if.comma_sel = phy_tx_if.comma_length_sel_out;
    //tx_phy connections
    assign phy_tx_if.start = end_if.start_tx;
    assign phy_tx_if.flit = end_if.flit_tx;
    assign phy_tx_if.comma_sel = end_if.comma_sel_tx;
    //tx to switch conneciton
    assign end_if.uart_out_tx = uart_tx_if.uart_out;
    assign end_if.done_tx = uart_tx_if.done;
    assign end_if.err_tx = uart_tx_if.tx_err;
endmodule

