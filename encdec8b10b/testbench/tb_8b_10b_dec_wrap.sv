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
    wrap_dec_8b_10b_if decif();
    wrap_enc_8b_10b_if encif();

    // Instantiate the 8b/10b encoder
    wrap_enc_8b_10b encoder_wrap (
        .CLK(CLK),
        .nRST(nRST),
        .enc_if(encif)
    );

    // Instantiate the 8b/10b decoder
    wrap_dec_8b_10b decoder_wrap (
        .CLK(CLK),
        .nRST(nRST),
        .dec_if(decif)
    );

    assign decif.enc_flit = encif.flit_out;

    always begin
        CLK = 0;
        #(CLK_PERIOD / 2.0);
        CLK = 1;
        #(CLK_PERIOD / 2.0);
    end

    initial begin
        decif.err = '0;
        nRST = 0;
        @(posedge CLK);
        nRST = 1;
        @(negedge CLK);
        for (logic [39:0] i = '0; i <= 40'd549755813888; i = 734391421 + i) begin
            encif.flit = i;
            encif.start = '1;
            encif.comma_sel = DATA_SEL;
            #(CLK_PERIOD);
            encif.start = '0;
            decif.done = '1;
            decif.comma_length_sel = SELECT_COMMA_DATA;
            #(CLK_PERIOD);
            decif.done = '0;
            if (i == decif.flit) $display("correct decoded data at %d", i);
            else $display("incorrect decoded data at %d",i);
            if ('1 == decif.done_out) $display("correct done at %d", i);
            else $display("incorrect done at %d",i);
            #(CLK_PERIOD);
        end
        $finish;
    end
endmodule

/* verilator coverage_on */
