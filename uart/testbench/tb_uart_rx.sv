`timescale 1ns / 10ps
`include "uart_rx_if.sv"
`include "uart_tx_if.sv"
`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
module tb_uart_rx;
import phy_types_pkg::*;
import chiplet_types_pkg::*;
  // Parameters
  parameter PORTCOUNT = 5;
  parameter CLKDIV_W = 10;
  parameter CLKDIV_COUNT = 10;
  parameter CLK_PERIOD = 10;


  // Testbench signals
  logic CLK;
  logic nRST;
  
  uart_rx_if rx();
  uart_tx_if tx();
  assign rx.uart_in = tx.uart_out;
  // Instantiate the uart_tx module
  uart_tx #(PORTCOUNT, CLKDIV_COUNT) uut_tx (
      .CLK(CLK),
      .nRST(nRST),
      .tx_if(tx)
  );

  // Instantiate the uart_rx module
  uart_rx #(PORTCOUNT, CLKDIV_COUNT) uut_rx (
      .CLK(CLK),
      .nRST(nRST),
      .rx_if(rx) 
  );

    task sendData;
    input logic [(PORTCOUNT * 10 - 1):0] data_in;
    begin
        tx.data = data_in;
        tx.start = 1'b1;
        tx.comma_sel = SELECT_COMMA_DATA; 
        @(posedge CLK);
        tx.data = 'b0;
        tx.start = 1'b0;
        tx.comma_sel =NADA;
        wait_cycles(CLKDIV_COUNT * 12 + 1);
        if(rx.data == data_in) $display("correct data recieved");
        else $display("incorect data recieved");
    end
    endtask
    
    task send2comma;
    input logic [(PORTCOUNT * 10 - 1):0] data_in;
    begin
        tx.data = data_in;
        tx.start = 1'b1;
        tx.comma_sel = SELECT_COMMA_1_FLIT; 
        @(posedge CLK);
        tx.data = 'b0;
        tx.start = 1'b0;
        tx.comma_sel =NADA;
        wait_cycles(CLKDIV_COUNT * 4 + 1);
        if(rx.data[9:0] == data_in[49:40]) $display("correct data recieved");
        else $display("incorect data recieved");
    end
    endtask

  task send4comma;
    input logic [(PORTCOUNT * 10 - 1):0] data_in;
    begin
        tx.data = data_in;
        tx.start = 1'b1;
        tx.comma_sel = SELECT_COMMA_2_FLIT;  
        @(posedge CLK);
        tx.data = 'b0;
        tx.start = 1'b0;
        tx.comma_sel =NADA;;
        wait_cycles(CLKDIV_COUNT * 6 + 1);
        if(rx.data[19:0] == data_in[49:30]) $display("correct data recieved");
        else $display("incorect data recieved");
    end
  endtask

    task wait_cycles;
    input integer wait_time;
    begin
        int i;
        i = 0;
        while (i != wait_time)begin
            @(posedge CLK);
            i++;
        end
    end
    endtask
    always begin
        CLK = 0;
        #(CLK_PERIOD / 2.0);
        CLK = 1;
        #(CLK_PERIOD / 2.0);
    end


  initial begin

    nRST = 'b0;
    @(posedge CLK);
    nRST = 'b1;
    @(posedge CLK);
    sendData({10'b1101010100, 10'b1010101011, 10'b1111000011, 10'b0000111100, 10'b1100110011});
    @(posedge CLK);
    sendData({10'b0101010101, 10'b1001100110, 10'b0011001100, 10'b1110001110, 10'b0110011001});
    @(posedge CLK);
    sendData({10'b1010101010, 10'b0110110011, 10'b1101101101, 10'b0001000100, 10'b1110110000});
    @(posedge CLK);
    send4comma({10'b101010111,10'b1011110101,30'b1});
    @(posedge CLK);
    send4comma({10'b1000100111,10'b1000110101,30'b1});
    @(posedge CLK);
    send2comma({10'b1011010111,10'b1111000001,30'b1});
    $finish;
  end






endmodule
