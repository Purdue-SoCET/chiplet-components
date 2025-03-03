`timescale 1ns / 10ps

/* verilator coverage_off */
module tb_endnode;


    localparam CLK_PERIOD = 10ns;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic CLK, nRST;
    long_hdr_t long_hdr;
    short_hdr_t short_hdr;
    msg_hdr_t msg_hdr;
    resp_hdr_t resp_hdr;
    switch_cfg_hdr_t switch_cfg;
    // clockgen
    always begin
        CLK = 0;
        #(CLK_PERIOD / 2.0);
        CLK = 1;
        #(CLK_PERIOD / 2.0);
    end
    task reset_dut;
    begin
        nRST = 0;
        @(posedge CLK);
        @(posedge CLK);
        @(negedge CLK);
        nRST = 1;
        @(posedge CLK);
        @(posedge CLK);
    end
    endtask
    typedef struct packed {
        comma_t comma_start;
        flit_enc_t [4:0] packet_data;
        comma_t comma_end;
    }test_packet_t;

    int addr_send;    
    flit_t header;
    flit_t [2:0]test_packet;

    int rand_data; 
    int seed;
    task send_packet;
    input logic [6:0]length;
    input logic [4:0]dest;
    input format_e format;
    input logic [7:0] meta_data; begin
  case(format)
        FMT_LONG_READ: begin
            long_hdr_t long_hdr;
            long_hdr.format = format;
            long_hdr.dest = dest;
            long_hdr.r0 = '0;
            long_hdr.lst_b = '0;
            long_hdr.fst_b = '0;
            long_hdr.length = length;
            // long_hdr.addr = 30'h0;
            // long_hdr.r1 = '0;
            header = flit_t'({meta_data, long_hdr});
        end

        FMT_LONG_WRITE: begin
            long_hdr_t long_hdr;
            long_hdr.format = format;
            long_hdr.dest = dest;
            long_hdr.r0 = '0;
            long_hdr.lst_b = '0;
            long_hdr.fst_b = '0;
            long_hdr.length = length;
            // long_hdr.addr = 30'h0;
            // long_hdr.r1 = '0;
            header = flit_t'({meta_data, long_hdr});
        end

        FMT_MEM_RESP: begin
            resp_hdr_t resp_hdr;
            resp_hdr.format = format;
            resp_hdr.dest = dest;
            resp_hdr.r = '0;
            resp_hdr.length = length;
            header = flit_t'({meta_data, resp_hdr});
        end

        FMT_MSG: begin
            msg_hdr_t msg_hdr;
            msg_hdr.format = format;
            msg_hdr.dest = dest;
            msg_hdr.msg_code = 16'h0;
            msg_hdr.length = length;
            header = flit_t'({meta_data, msg_hdr});
        end

        FMT_SWITCH_CFG: begin
            switch_cfg_hdr_t switch_cfg;
            switch_cfg.format = format;
            switch_cfg.dest = dest;
            switch_cfg.data_hi = 8'h0;
            switch_cfg.addr = 9'h0;
            switch_cfg.data_lo = 7'h0;
            header = flit_t'({meta_data, switch_cfg});
        end

        FMT_SHORT_READ: begin
            short_hdr_t short_hdr;
            short_hdr.format = format;
            short_hdr.dest = dest;
            short_hdr.addr = 19'h0;
            short_hdr.length = length[3:0];
            header = flit_t'({meta_data, short_hdr});
        end

        FMT_SHORT_WRITE: begin
            short_hdr_t short_hdr;
            short_hdr.format = format;
            short_hdr.dest = dest;
            short_hdr.addr = 19'h0;
            short_hdr.length = length[3:0];
            header = flit_t'({meta_data, short_hdr});
        end

        default: begin
            header = '0;
        end
    
    endcase




    send_start_komma(START_PACKET_SEL);
    // wait_rx_komma_recieve(START_PACKET_SEL);
    addr_send = 0;
    send_start_header(header);
    if (format == FMT_LONG_READ || format == FMT_LONG_WRITE) begin
        send_data(32'h8675309,meta_data);
    end

    // check_rx_data_recieve(header,DATA_SEL, '0);
    for (int i =0; i <= int'(length); i++) begin
        send_data(32'h8675309,meta_data);
        // check_rx_data_recieve(flit_t'({meta_data,rand_data}),DATA_SEL,'0);
    end
    tx_end_if.packet_done_tx = '1;
    @(posedge CLK);
    tx_end_if.packet_done_tx = '0;
    while(tx_if.done != '1) begin
        @(posedge CLK);
    end
    // wait_tx_send_komma();
    end
    endtask


    task  send_start_header;
    input flit_t flit_out;
    begin
        tx_end_if.flit_tx = flit_out;
        tx_end_if.send_next_flit_tx = '1;
        @(posedge CLK);
        tx_end_if.send_next_flit_tx = '0;
        // while (tx_end_if.get_data == '0) begin
        //     @(posedge CLK);
        // end
        wait_tx_send_header(meta_data,header);    end
    endtask

    task send_data;
    input logic [31:0] flit;
    input logic[7:0] meta_data;
    begin
        // tx_end_if.comma_sel_tx = DATA_SEL;
        tx_end_if.flit_tx = flit_t'({meta_data,flit}); 
        tx_end_if.send_next_flit_tx = '1;
        @(posedge CLK);
        tx_end_if.send_next_flit_tx = '0;
        tx_end_if.flit_tx = '0;
        // while (tx_end_if.get_data == '0) begin
        //     @(posedge CLK);
        // end
        wait_tx_send_data(meta_data);
    end
    endtask
    
    task send_start_komma;
    input comma_sel_t comma_sel;
    begin
    @(negedge CLK);
    tx_end_if.start_tx = '1;
    @(posedge CLK);
    tx_end_if.start_tx = '0;
    wait_tx_send_komma();
    end
    endtask

    task wait_tx_send_komma; begin
    while(tx_end_if.get_data != '1) begin
    @(posedge CLK);
    end
    end
    endtask
    
    task wait_tx_send_data;
    input logic [7:0]  meta_data;
     begin
        while (tx_end_if.get_data != '1) begin
            @(posedge CLK);
            if (rx_end_if.done_rx) begin
                assert(flit_t'({ meta_data,32'h8675309}) == rx_end_if.flit_rx)
                else $display("mistake with expected flit out value of %h actual value of %h",flit_t'({ meta_data,32'h8675309}),rx_end_if.flit_rx);
            end
    end
     end
    endtask
    
    task wait_tx_send_header;
    input  logic [7:0] meta_data;
    input flit_t header;
     begin
        @(posedge CLK);
        while (rx_end_if.done_rx != '1) begin
            @(posedge CLK);
            if (rx_end_if.done_rx == '1) begin
                assert(flit_t'({ meta_data,header}) == rx_end_if.flit_rx)
                else $display("mistake with expected flit out value of %h actual value of %h",flit_t'({ meta_data,32'h8675309}),rx_end_if.flit_rx);
            end
    end
        end
    endtask

    task send_komma;
    input test_packet_t test_packet;
    input comma_sel_t comma_sel;
    begin
        send_comma_err(test_packet.comma_start);
        
        for (int j = 0; j < 5; j= j+1) begin
            send_data_err(test_packet.packet_data[j]);
        end
        send_comma_err(test_packet.comma_end);

        for (int i = 0; i < 8; i = i+ 1) begin
            @(posedge CLK);
        end
        if ( comma_sel == ACK_SEL) begin
            while (rx_end_if.flit_rx[31:28] != KOMMA_PACKET) begin
                @(posedge CLK);
            end
        end
        else if (comma_sel == GRTCRED0_COMMA) begin
            while (rx_end_if.grtcred_rx[0] == '0) begin
                @(posedge CLK);
            end
        end
        
        else if (comma_sel == GRTCRED1_COMMA) begin
            while (rx_end_if.grtcred_rx[1]== '0) begin
                @(posedge CLK);
            end
        end
    end
    endtask

    task send_data_err;
    input flit_enc_t enc_flit;

    begin
        send_bits('0);
        for (int k =9; k >= 0; k= k-1) begin
            send_bits(enc_flit[(k * 5) + 4 -: 5]);
        end
        send_bits('1);
        @(posedge CLK);
    end
    endtask
    
    
    task send_comma_err;
    input comma_t comma;
    begin
        send_bits('0);
        send_bits(comma[9:5]);
        send_bits(comma[4:0]);
        send_bits('1);
        @(posedge CLK);
    end
    endtask

    task send_bits; 
    input logic [4:0] bits;
    begin     
        uart_tx_rx_if.uart_in = bits;
        for (int i = 0; i < 10; i= i +1) begin
            @(posedge CLK);
        end
    end
    endtask
    endnode_if tx_end_if();
    endnode_if rx_end_if();
    uart_tx_if tx_if();
    uart_rx_if uart_tx_rx_if();
    uart_rx_if rx_if();
    uart_tx_if empty_if2();
    endnode #() transmitter (.CLK(CLK),.nRST(nRST),.end_if(tx_end_if));
    uart_baud #() transmitter_uart(.CLK(CLK),.nRST(nRST),.tx_if(tx_if),.rx_if(uart_tx_rx_if));
    endnode #() recieveer (.CLK(CLK),.nRST(nRST),.end_if(rx_end_if));
    uart_baud #() rx_uart(.CLK(CLK),.nRST(nRST),.rx_if(rx_if),.tx_if(empty_if2));
    logic [7:0] meta_data;
    logic [4:0] dest;
    assign rx_if.uart_in =  tx_if.uart_out;
    
    assign rx_end_if.enc_flit_rx = rx_if.data;
    assign rx_end_if.done_in_rx = rx_if.done;
    assign rx_end_if.comma_length_sel_in_rx = rx_if.comma_sel;
    assign rx_end_if.err_in_rx = rx_if.rx_err;
    
    assign tx_end_if.done_in_rx = uart_tx_rx_if.done;
    assign tx_end_if.comma_length_sel_in_rx = uart_tx_rx_if.comma_sel;
    assign tx_end_if.enc_flit_rx = uart_tx_rx_if.data;
    assign tx_end_if.err_in_rx = uart_tx_rx_if.rx_err;
    
    assign tx_if.data = tx_end_if.data_out_tx;
    assign tx_if.comma_sel = tx_end_if.comma_sel_tx_out;
    assign txvc _if.start = tx_end_if.start_out_tx;
    assign tx_end_if.done_tx = tx_if.done;
    test_packet_t [2:0]test_vectors;
    
    initial begin
        meta_data = 8'b10100101;
        dest = 'd2;
        nRST = 'd1;
        tx_end_if.packet_done_tx = '0;
        reset_dut;
        uart_tx_rx_if.uart_in = 'h1f; 
         tx_end_if.flit_tx = {meta_data, {32{1'b1}}};
        tx_end_if.send_next_flit_tx  ='0;
        //test kommas
        test_vectors[0].comma_start = START_COMMA;
        test_vectors[0].packet_data[0] = flit_enc_t'('h2a948d1846112);
        test_vectors[0].packet_data[1] = flit_enc_t'('h2a9418c75c925);
        test_vectors[0].packet_data[2] = flit_enc_t'('h2a9418c75c925);
        test_vectors[0].packet_data[3] = flit_enc_t'('h2a9418c75c925);
        test_vectors[0].packet_data[4] = flit_enc_t'('h2a951cf11289a);
        test_vectors[0].comma_end = END_COMMA;
        
        test_vectors[1].comma_start = START_COMMA;
        test_vectors[1].packet_data[0] = flit_enc_t'('h2a948d1846112);
        test_vectors[1].packet_data[1] = flit_enc_t'('h2a9418c75c92 );
        test_vectors[1].packet_data[2] = flit_enc_t'('h2a9418c75c925);
        test_vectors[1].packet_data[3] = flit_enc_t'('h2a9418c75c925);
        test_vectors[1].packet_data[4] = flit_enc_t'('h2a951cf11289a);
        test_vectors[1].comma_end = END_COMMA;


        // send_komma(START_PACKET_SEL);
        // wait_rx_komma_recieve(START_PACKET_SEL);

        // send_komma(END_PACKET_SEL);
        // wait_rx_komma_recieve(END_PACKET_SEL);
        
        // send_komma(RESEND_PACKET0_SEL);
        // wait_rx_komma_recieve(RESEND_PACKET0_SEL);
        
        // send_komma(RESEND_PACKET1_SEL);
        // wait_rx_komma_recieve(RESEND_PACKET1_SEL);
        
        // send_komma(RESEND_PACKET2_SEL);
        // wait_rx_komma_recieve(RESEND_PACKET2_SEL);
        
        // send_komma(RESEND_PACKET3_SEL);
        // wait_rx_komma_recieve(RESEND_PACKET3_SEL);
        
        // send_komma(ACK_SEL);
        // wait_rx_komma_recieve(ACK_SEL);
        
        // send_komma(NACK_SEL);
        // wait_rx_komma_recieve(NACK_SEL);
        
        //test data transmisison

        send_packet('d2,dest,FMT_LONG_WRITE,meta_data);
        send_packet(0,dest,FMT_LONG_READ,meta_data);
        send_packet(9,dest,FMT_MEM_RESP,meta_data);
        send_packet(54,dest,FMT_LONG_WRITE,meta_data);
        send_packet(0,dest,FMT_SHORT_READ,meta_data);
        send_packet(6,dest,FMT_SHORT_WRITE,meta_data);
        send_packet(0,dest,FMT_MSG,meta_data);
        send_packet(0,dest,FMT_SWITCH_CFG,meta_data);
        send_packet(0,dest,KOMMA_PACKET,meta_data);
        //send ack
        @(posedge CLK);
        tx_end_if.grtcred_tx[0] = '1;
        @(posedge CLK);
        tx_end_if.grtcred_tx[0] = '0;
        while( tx_if.done != '1) begin
            @(posedge CLK);
        end
        while (rx_end_if.grtcred_rx[0] != '1) begin
            @(negedge CLK);
        end
        assert(rx_end_if.grtcred_rx[0] == '1)
                else $display("mistake with expected grt_cred_0 %d",rx_end_if.grtcred_rx[0]);


        @(posedge CLK);
        tx_end_if.grtcred_tx[1] = '1;
        @(posedge CLK);
        tx_end_if.grtcred_tx[1] = '0;
        while( tx_if.done != '1) begin
            @(posedge CLK);
        end
        while (rx_end_if.grtcred_rx[1] != '1) begin
            @(negedge CLK);
        end
        assert(rx_end_if.grtcred_rx[1] == '1)
                else $display("mistake with expected grt_cred_0 %d",rx_end_if.grtcred_rx[1]);

        @(posedge CLK);
        @(posedge CLK);
        @(posedge CLK);
        
        @(posedge CLK);
        @(posedge CLK);
        @(posedge CLK);
        
        @(posedge CLK);
        @(posedge CLK);
        @(posedge CLK);

        tx_end_if.flit_tx = {meta_data,KOMMA_PACKET,meta_data[4:0],19'b0,ACK_SEL};
        tx_end_if.start_tx = '1;
        @(posedge CLK);
        tx_end_if.start_tx = '0;
        while (rx_end_if.done_rx != '1) begin
            @(negedge CLK);
        end
        assert (rx_end_if.flit_rx =={meta_data,KOMMA_PACKET,meta_data[4:0],19'b0,ACK_SEL} )
            else $display("mistake with ACK COMMA");
        // send_komma(test_vectors[0],ACK_SEL);
        // send_komma(test_vectors[1],RESEND_PACKET1_SEL);

        $finish;
    end
endmodule

/* verilator coverage_on */

