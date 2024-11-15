// Created:     7/3/2021
// Author:      Huy-Minh Tran
// Description: Counter 

`timescale 1ns / 10ps

module rx_timer
#(
    parameter int NBITS = 4,
    parameter [(NBITS -1):0] COUNT_TO
)
(
    input CLK,
    input nRST,
    input clear,
    input count_enable,
    input [(NBITS - 1) : 0] overflow_val,
    output logic [(NBITS - 1) : 0] count_out,
    output logic overflow_flag
);
    logic [(NBITS - 1) : 0] count;
    logic [(NBITS - 1) : 0] n_count;
    logic of; //overflow 
    logic n_of; //next_overflow
    assign count_out = count;
    assign overflow_flag = of;

    always_ff @(posedge CLK, negedge nRST) begin
        if (nRST == 1'b0) begin
            count <= (COUNT_TO / 2);
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

        if (clear == 1'b1) begin
            n_count = (COUNT_TO / 2); 
        end else if (count_enable) begin
            if (count + 1 > (COUNT_TO))
                n_count = 1;
            else 
                n_count = count + 1;
        end else begin 
            n_count = count;
        end
            
        if (n_count == (COUNT_TO)) begin
            n_of = 1'b1;
        end else begin
            n_of = 1'b0;
        end
    end 
endmodule
