`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_8b_10b_dec_wrap();
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    localparam CLK_PERIOD = 10;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic CLK;
    logic nRST;

    wrap_enc_8b_10b_if encif();
    phy_manager_rx_if mngrx_if();
    // Instantiate the 8b/10b encoder
    phy_manager_tx encoder_wrap (
        .CLK(CLK),
        .nRST(nRST),
        .enc_if(encif)
    );

    // Instantiate the 8b/10b decoder
    phy_manager_rx decoder_wrap (
        .CLK(CLK),
        .nRST(nRST),
        .mngrx_if(mngrx_if)
    );
    assign mngrx_if.enc_flit_rx = encif.flit_out;
    always begin
        CLK = 0;
        #(CLK_PERIOD / 2.0);
        CLK = 1;
        #(CLK_PERIOD / 2.0);
    end

    initial begin
        mngrx_if.uart_err_rx = '0;
        nRST = 0;
        @(posedge CLK); nRST = 1;
        encif.start = '1;
        encif.comma_sel = START_PACKET_SEL;
        @(posedge CLK);
        mngrx_if.done_uart_rx = '1;
        encif.start = '0;
        mngrx_if.comma_length_sel_rx = SELECT_COMMA_1_FLIT;
        @(posedge CLK);
               mngrx_if.done_uart_rx = '0;
        for (logic [39:0] i = '0; i <= 40'h9755813888; i = 40'h3343914211 + i) begin
          @(posedge CLK);
          encif.flit = i;
          encif.start = '1;
          encif.comma_sel = DATA_SEL;
          @(posedge CLK);
          encif.start = '0;
          mngrx_if.done_uart_rx = '1;
          mngrx_if.comma_length_sel_rx = SELECT_COMMA_DATA;
          @(posedge CLK);
          mngrx_if.done_uart_rx = '0;
          @(posedge CLK);
          @(posedge CLK);
          @(posedge CLK);
          @(posedge CLK);
          #(1);
          assert (i == mngrx_if.flit) $display("correct decoded data at %d", i);
          else $display("incorrect decoded data at %d",i);
          assert ('1 == mngrx_if.done_out) $display("correct done at %d", i);
          else $display("incorrect done at %d",i);

        end 
        $finish;
    end
endmodule

/* verilator coverage_on */
