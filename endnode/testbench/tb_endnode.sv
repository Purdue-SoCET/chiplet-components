`timescale 1ns / 10ps

/* verilator coverage_off */

module tb_endnode ();

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
    
    int addr_send;    
    flit_t header;
    int rand_data; 
    int seed;
    task send_packet;
    input logic length;
    input logic dest;
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
            long_hdr.addr = 30'h0;
            long_hdr.r1 = '0;
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
            long_hdr.addr = 30'h0;
            long_hdr.r1 = '0;
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
            short_hdr.length = length;
            header = flit_t'({meta_data, short_hdr});
        end

        FMT_SHORT_WRITE: begin
            short_hdr_t short_hdr;
            short_hdr.format = format;
            short_hdr.dest = dest;
            short_hdr.addr = 19'h0;
            short_hdr.length = length;
            header = flit_t'({meta_data, short_hdr});
        end

        default: begin
            header = '0;
        end
    
    endcase
    send_komma(START_PACKET_SEL);
    // wait_rx_komma_recieve(START_PACKET_SEL);
    addr_send = 0;
    if (format == FMT_LONG_READ || format == FMT_LONG_WRITE) begin
        addr_send = 1;
    end
    else if (format == FMT_SWITCH_CFG) begin
        addr_send =  -1;
    end
    send_header(format,meta_data,header);
    // check_rx_data_recieve(header,DATA_SEL, '0);
    for (int i =0; i < length + 1 + addr_send; i++) begin
        seed = 5;
        rand_data= $random(seed); 
        send_data(rand_data,meta_data);
        // check_rx_data_recieve(flit_t'({meta_data,rand_data}),DATA_SEL,'0);
    end
    tx_end_if.packet_done_tx = '1;
    @(posedge CLK);
    tx_end_if.packet_done_tx = '0;
    wait_tx_send_komma();
    end
    endtask


    task  send_header;
    input format_e format;
    input meta_data;
    input flit_t flit_out;
    begin
        // tx_end_if.start_tx = '1;
        tx_end_if.flit_tx = flit_out;
        // tx_end_if.start_tx = '0;
        while (tx_end_if.get_data == '0) begin
            @(posedge CLK);
        end
        @(posedge CLK);
        tx_end_if.flit_tx = '0;
        wait_tx_send_data();
    end
    endtask

    task send_data;
    input logic [31:0] flit;
    input logic[7:0] meta_data;
    begin
        // tx_end_if.comma_sel_tx = DATA_SEL;
        tx_end_if.flit_tx = flit_t'({meta_data,flit}); 

        tx_end_if.start_tx = '1;
        @(posedge CLK);
        tx_end_if.start_tx = '0;
        while (tx_end_if.get_data == '0) begin
            @(posedge CLK);
        end
        tx_end_if.flit_tx = '0;
        wait_tx_send_data();
    end
    endtask
    
    task send_komma;
    input comma_sel_t comma_sel;
    begin
    @(posedge CLK);
    tx_end_if.start_tx = '1;
    @(posedge CLK);
    tx_end_if.start_tx = '0;
    wait_tx_send_komma();
    end
    endtask

    task wait_tx_send_komma; begin
    for(int i =0; i < 38; i = i + 1) begin
    @(posedge CLK);
    end
    end
    endtask
    
    task wait_tx_send_data; begin
    for(int i =0; i < 120; i = i + 1) begin
    @(posedge CLK);
    end
    end
    endtask


    task wait_rx_komma_recieve;
    input comma_sel_t comma_sel_exp;
     begin
    
    while(rx_end_if.done_rx != '1) begin
    @(posedge CLK);
    end
    // assert(rx_end_if.comma_sel_rx == comma_sel_exp)
    // else $display("mistake with comma_expected. expected value of %d actual value of %d at time: " ,comma_sel_exp,rx_end_if.comma_sel_rx);
    end
    endtask
    
    task check_rx_data_recieve;
    input flit_t flit_expected;
    input comma_sel_t comma_sel_exp;
    input  logic crc_corr_rx;
     begin
    
    while(rx_end_if.done_rx != '1) begin
    @(posedge CLK);
    end
    // assert(rx_end_if.comma_sel_rx == comma_sel_exp)
    // else $display("mistake with comma_expected. expected value of %d actual value of %d",comma_sel_exp,rx_end_if.comma_sel_rx);
    assert(flit_expected == rx_end_if.flit_rx)
    else $display("mistake with expected flit out value of %d actual value of %d",flit_expected,rx_end_if.flit_rx);
    end
    endtask

    


    endnode_if tx_end_if();
    endnode_if rx_end_if();
    uart_tx_if tx_if();
    uart_rx_if empty_if();
    uart_rx_if rx_if();
    uart_tx_if empty_if2();
    endnode #() transmitter (.CLK(CLK),.nRST(nRST),.end_if(tx_end_if));
    uart_baud #() transmitter_uart(.CLK(CLK),.nRST(nRST),.tx_if(tx_if),.rx_if(empty_if));
    endnode #() recieveer (.CLK(CLK),.nRST(nRST),.end_if(rx_end_if));
    uart_baud #() rx_uart(.CLK(CLK),.nRST(nRST),.rx_if(rx_if),.tx_if(empty_if2));
    logic [7:0] meta_data;
    int dest;
    assign rx_if.uart_in =  tx_if.uart_out;
    
    assign rx_end_if.enc_flit_rx = rx_if.data;
    assign rx_end_if.done_in_rx = rx_if.done;
    assign rx_end_if.comma_length_sel_in_rx = rx_if.comma_sel;
    assign rx_end_if.err_in_rx = rx_if.rx_err;

    assign tx_if.data = tx_end_if.data_out_tx;
    assign tx_if.comma_sel = tx_end_if.comma_sel_tx_out;
    assign tx_if.start = tx_end_if.start_out_tx;
    assign tx_end_if.done_tx = tx_if.done;
    
    
    initial begin
        meta_data = 8'b10100101;
        dest = 2;
        nRST = 1;
        tx_end_if.packet_done_tx = '0;
        reset_dut;
         tx_end_if.flit_tx = {meta_data, {32{1'b1}}};
        //test kommas
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


        send_packet(4,dest,FMT_LONG_WRITE,meta_data);
        send_packet(0,dest,FMT_LONG_READ,meta_data);
        send_packet(9,dest,FMT_MEM_RESP,meta_data);
        send_packet(54,dest,FMT_LONG_WRITE,meta_data);
        send_packet(0,dest,FMT_SHORT_READ,meta_data);
        send_packet(6,dest,FMT_SHORT_WRITE,meta_data);
        send_packet(0,dest,FMT_MSG,meta_data);
        send_packet(0,dest,FMT_SWITCH_CFG,meta_data);
        $finish;
    end
endmodule

/* verilator coverage_on */

