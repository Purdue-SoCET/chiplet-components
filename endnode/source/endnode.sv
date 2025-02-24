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
    socetlib_counter #(.NBITS(16)) crc_counter
        (.CLK(CLK),
         .nRST(nRST),
         .count_enable(~phy_rx_if.crc_corr && packet_done),
         .overflow_val('d65535),
         .count_out(end_if.crc_fail_cnt)
        );
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
    
    always_comb begin
        if (phy_rx_if.comma_sel == ACK_SEL && phy_rx_if.done_out) begin
            end_if.flit_rx = {phy_rx_if.flit.vc, phy_rx_if.flit.id,phy_rx_if.flit.req, KOMMA_PACKET,node_id_t'(phy_rx_if.flit.req), 19'b0,ACK_SEL};
        end
        else begin
            end_if.flit_rx = phy_rx_if.flit;
        end
    end
    // //comma to switch response
    // assign end_if.nack_recieved = phy_rx_if.comma_sel == NACK_SEL;
    // assign end_if.rs0_recieved = phy_rx_if.comma_sel == RESEND_PACKET0_SEL;
    // assign end_if.rs1_recieved = phy_rx_if.comma_sel == RESEND_PACKET1_SEL;
    // assign end_if.rs2_recieved = phy_rx_if.comma_sel == RESEND_PACKET2_SEL;
    // assign end_if.rs3_recieved = phy_rx_if.comma_sel == RESEND_PACKET3_SEL;
    // assign end_if.ack_recieved = phy_rx_if.comma_sel == ACK_SEL;
    
    //rx to switch connections
    assign end_if.done_rx = phy_rx_if.done_out;
    assign end_if.err_rx = err_store;
    assign end_if.crc_corr_rx = phy_rx_if.crc_corr;
    // assign end_if.flit_rx = phy_rx_if.flit;
    //phy rx to tx
    
    // //uart_tx connections
    assign end_if.data_out_tx = phy_tx_if.enc_flit;
    assign end_if.start_out_tx = phy_tx_if.start_out;
    assign end_if.comma_sel_tx_out = phy_tx_if.comma_length_sel_out;

    //tx_phy connections
    assign phy_tx_if.flit = end_if.flit_tx;
    assign phy_tx_if.done = end_if.done_tx;
    assign phy_tx_if.packet_done = end_if.packet_done_tx;
    assign phy_tx_if.rx_header = {end_if.flit_tx.vc, end_if.flit_tx.id, end_if.flit_tx.req};
    // assign phy_tx_if.data_write = end_if.start_tx;
    assign end_if.get_data = phy_tx_if.get_data;
    assign phy_tx_if.grtcred0_write = end_if.grtcred_tx[0];
    assign phy_tx_if.grtcred1_write = end_if.grtcred_tx[1];
    assign end_if.grtcred_rx[0] = phy_rx_if.comma_sel == GRTCRED0_SEL && phy_rx_if.done_out;
    assign end_if.grtcred_rx[1] = phy_rx_if.comma_sel == GRTCRED1_SEL   &&phy_rx_if.done_out;
    assign phy_tx_if.new_flit = end_if.send_next_flit_tx;

    comma_header_t komma_hdr;
    always_comb begin
        komma_hdr = comma_header_t'(end_if.flit_tx.payload);
        phy_tx_if.ack_write = '0;
        phy_tx_if.data_write = '0;
        if (komma_hdr.format == KOMMA_PACKET && end_if.start_tx) begin 
            case(komma_hdr.comma_sel) 
                ACK_SEL: begin
                    phy_tx_if.ack_write = '1;
                end
                default: begin
                end
            endcase
        end
        else if (end_if.start_tx) begin
            phy_tx_if.data_write = '1;
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

