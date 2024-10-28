module uart_rx_tb;

  // Parameters
  parameter PORTCOUNT = 5;
  parameter CLKDIV_W = 10;
  parameter CLKDIV_COUNT = (CLKDIV_W)'d10;

  // Testbench signals
  logic CLK;
  logic nRST;
  logic start;
  logic [1:0] comma_sel;
  logic [(PORTCOUNT * 10 - 1):0] tx_data;
  logic done_tx, tx_err;
  logic [(PORTCOUNT - 1):0] uart_out;
  
  logic [(PORTCOUNT - 1):0] uart_in; 
  logic [(PORTCOUNT * 10 - 1):0] received_data; 
  logic done_rx, rx_err, data_ready;

  // Instantiate the uart_tx module
  uart_tx #(PORTCOUNT, CLKDIV_W, CLKDIV_COUNT) uut_tx (
      .CLK(CLK),
      .nRST(nRST),
      .start(start),
      .comma_sel(comma_sel),
      .data(tx_data),
      .done(done_tx),
      .tx_err(tx_err),
      .uart_out(uart_out) 
  );

  // Instantiate the uart_rx module
  uart_rx #(PORTCOUNT, CLKDIV_W) uut_rx (
      .clk(CLK),
      .nRST(nRST),
      .uart_in(uart_out), 
      .comma_sel(comma_sel),
      .data(received_data), 
      .done(done_rx), 
      .rx_err(rx_err) 
  );

    task sendData;
    input logic [(PORTCOUNT * 10) - 1] data_in;
    begin
        tx_data = data_in;
        wait(CLKDIV_COUNT * 12 - 1);
        assert(received_data == data_in) $display("correct data recieved");
        else $display("incorect data recieved");
    end
    endtask

    task wait;
    input integer wait_time;
    begin
        int i =0;
        while (i != wait_time)begin
            @(posedge CLK);
            i++;
        end
    end
    endtask

  initial begin

    nRST = 'b0;
    @(posedge CLK);
    nRST = 'b1;
    @(posedge CLK);
    sendData({10'b1101010100, 10'b1010101011, 10'b1111000011, 10'b0000111100, 10'b1100110011});
    @(posedge CLK);
    sendData({10'b0101010101, 10'b1001100110, 10'b0011001100, 10'b1110001110, 10'b0110011001});
    @(posedge CLK);
    sendData({10'b1010101010, 10'b0110110011, 10'b1101101101, 10'b0001000100, 10'b1111110000});
    @(posedge CLK);
  end






endmodule
