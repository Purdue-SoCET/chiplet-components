`timescale 1ns / 10ps
/* verilator coverage_off */

module tb_8b_10b_dec ();

    localparam CLK_PERIOD = 10  ;
    
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars;
    end

    logic CLK;
    logic nRST;
    logic [7:0] data_in;
    logic [9:0] encoded_data;
    logic [7:0] decoded_data;

    // Instantiate the 8b/10b encoder
    enc_8b10b encoder (
        .CLK(CLK),
        .nRST(nRST),
        .data_in(data_in),
        .data_out(encoded_data)
    );

    // Instantiate the 8b/10b decoder
    dec_8b10b decoder (
        .CLK(CLK),
        .nRST(nRST),
        .data_in(encoded_data),
        .data_out(decoded_data)
    );

    always begin
        CLK = 0;
        #(CLK_PERIOD / 2.0);
        CLK = 1;
        #(CLK_PERIOD / 2.0);
    end

    initial begin
      
        nRST = 0;
        @(posedge CLK); nRST = 1;
        for (int i = 0; i < 127; i = i + 1) begin
          @(posedge CLK);
          data_in = i;
          #(1);
          assert (i == decoded_data) $display("correct decoded data at %d", i);
          else $display("incorrect decoded data at %d",i);
          assert (encoded_data[4:0] != 'b0 && encoded_data[4:0] != 'b11111 && encoded_data[9:5] != 'b0 && encoded_data[9:5] != 'b11111) $display("no start and stop signals for uart geerated");
          else $display("incorrect start and stop uart created at %d",i);
        end 
        $finish;
    end
endmodule

/* verilator coverage_on */

