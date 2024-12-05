// Created:     7/3/2021
// Author:      Huy-Minh Tran
// Description: Counter 

`timescale 1ns / 10ps

module socetlib_counter
#(
    parameter BITS_WIDTH = 4
)
(
    input logic clk,
    input logic nRST,
    input logic clear,
    input logic count_enable,
    input logic [(BITS_WIDTH - 1) : 0] overflow_val,
    output logic [(BITS_WIDTH - 1) : 0] count_out,
    output logic overflow_flag
);
    reg [(BITS_WIDTH - 1) : 0] count;
    reg [(BITS_WIDTH - 1) : 0] n_count;
    reg of; //overflow 
    reg n_of; //next_overflow

    assign count_out = count;
    assign overflow_flag = of;

    always_ff @(posedge clk, negedge nRST) begin
        if (nRST == 1'b0) begin
            count <= 0;
            of <= 0;
        end
        else begin
            count <= n_count;
            of <= n_of;
        end
    end

    always_comb begin
        n_count = 0;
        n_of = 0;

        if (clear == 1'b1) 
            n_count = 0; 

        else if (count_enable) begin
            if (count + 1 > overflow_val)
                n_count = 1;
            else 
                n_count = count + 1;
        end

        else 
            n_count = count;
            
        if (n_count == overflow_val) begin
            n_of = 1'b1;
        end
        else begin
            n_of = 1'b0;
        end
    end 
endmodule
