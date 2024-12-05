`timescale 1ns / 10ps

module endnode #() (
    input logic CLK, nRST, endnode_if.eif end_if
);
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    localparam PORTCOUNT = 5;
    localparam EXPECTED_BAUD_RATE = 1000000;
    localparam FREQUENCY = 10000000;
    logic err_store;
    phy_manager_tx_if phy_tx_if();
    phy_manager_rx_if phy_rx_if();
    // uart_rx_if uart_rx_if();
    // uart_tx_if uart_tx_if();

    phy_manager_tx #(.PORTCOUNT(PORTCOUNT)) phy_tx 
        (.CLK(CLK),
         .nRST(nRST),
         .phy_if(phy_tx_if));
    
    phy_manager_rx #(.PORTCOUNT(PORTCOUNT)) phy_rx
        (.CLK(CLK),
        .nRST(nRST),
        .mngrx_if(phy_rx_if));

    // uart_baud #(.PORTCOUNT(PORTCOUNT),.FREQUENCY(FREQUENCY),.EXPECTED_BAUD_RATE(EXPECTED_BAUD_RATE)) uarts
    //     (.CLK(CLK),
    //     .nRST(nRST),
    //     .rx_if(uart_rx_if),
    //     .tx_if(uart_tx_if));

    //uart_rx_connection
    // assign uart_rx_if.uart_in = end_if.uart_rx_in; 
    //rx phy connection
    assign phy_rx_if.enc_flit_rx = end_if.enc_flit_rx;
    assign phy_rx_if.done_uart_rx = end_if.done_in_rx;// &&  phy_rx_if.comma_sel == DATA_SEL;
    assign phy_rx_if.comma_length_sel_rx = end_if.comma_length_sel_in_rx;
    assign phy_rx_if.uart_err_rx = end_if.err_in_rx;

    //rx to switch connections
    assign end_if.done_rx = phy_rx_if.done_out;
    assign end_if.err_rx = err_store;
    assign end_if.crc_corr_rx = phy_rx_if.crc_corr;
    assign end_if.flit_rx = phy_rx_if.flit;
    //phy rx to tx
    
    // //uart_tx connections
    assign end_if.data_out_tx = phy_tx_if.enc_flit;
    assign end_if.start_out_tx = phy_tx_if.start_out;
    assign end_if.comma_sel_tx_out = phy_tx_if.comma_length_sel_out;

    //tx_phy connections
    assign phy_tx_if.flit = end_if.flit_tx;
    assign phy_tx_if.done = end_if.done_tx;
    assign phy_tx_if.packet_done = end_if.packet_done_tx;
    assign phy_tx_if.rx_header = {phy_rx_if.flit.vc, phy_rx_if.flit.id, phy_rx_if.flit.req};
    assign phy_tx_if.data_write = end_if.start_tx;
    assign end_if.get_data = phy_tx_if.get_data;
    always_comb begin
        if (phy_rx_if.packet_done && phy_rx_if.comma_sel == END_PACKET_SEL) begin
            phy_tx_if.ack_write = phy_rx_if.crc_corr && ~err_store && ~ phy_tx_if.ack_cnt_full;
            phy_tx_if.nack_write = phy_rx_if.crc_corr && ~err_store && phy_tx_if.ack_cnt_full;
            phy_tx_if.rs0_write = (~phy_rx_if.crc_corr || ~err_store) && phy_rx_if.flit.id == 'd0;
            phy_tx_if.rs1_write = (~phy_rx_if.crc_corr || ~err_store) && phy_rx_if.flit.id == 'd1;
            phy_tx_if.rs2_write = (~phy_rx_if.crc_corr || ~err_store) && phy_rx_if.flit.id == 'd2;
            phy_tx_if.rs3_write = (~phy_rx_if.crc_corr || ~err_store) && phy_rx_if.flit.id == 'd3;
        end
    end

    always_ff @(posedge CLK, negedge nRST) begin
        if (~nRST) begin
            err_store <= '0;
        end
        if (phy_rx_if.packet_done) begin
            err_store <= '0;
        end
        else if (err_store =='1)begin
            err_store <= '1;
        end
        else begin
            err_store <= phy_rx_if.err_out;
        end
    end
    // //tx to switch conneciton
endmodule

