`timescale 1ns / 10ps

module tb_switch ()

    localparam CLK_PERIOD = 10ns;

    logic clk, n_rst

    switch DUT(.clk(clk), .n_rst(n_rst), );

    task reset_dut;
        begin
            n_rst = 0;
            @(posedge clk);
            @(posedge clk);
            @(negedge clk);
            n_rst = 1;
            @(posedge clk);
            @(posedge clk);
        end
    endtask

    initial begin
        n_rst = 1'b1;
        reset_dut;




        $finish
    end
endmodule