// Created:     7/3/2021
// Author:      Huy-Minh Tran
// Description: Counter 
//note check != 0 edge case for decrementing is in arbitrator no need for it here but should be added if removed from higher level module
`timescale 1ns / 10ps

// `include "arb_counter_if.sv"
module arb_counter #(parameter NBITS = 4)
(
    input CLK,
    input nRST,
    arb_counter_if.cnt cnt_if
);
    logic [(NBITS - 1) : 0] count;
    logic [(NBITS - 1) : 0] n_count;
    assign cnt_if.count = count;

    always_ff @(posedge CLK, negedge nRST) begin
        if (nRST == 1'b0) begin
            count <= 0;
        end
        else begin
            count <= n_count;
        end
    end

    always_comb begin
        n_count = 0;
        cnt_if.overflow = 0;
        if (cnt_if.clear == 1'b1) begin
            n_count = 0; 
        end else  if (cnt_if.en && cnt_if.dec) begin
            n_count = count;
        end 
        else if (cnt_if.en) begin
            if (count + 1 > (2** NBITS - 1))
                n_count = count;
            else 
                n_count = count + 1;
        end
        else if (cnt_if.dec) begin
            n_count = count - 1;
        end
         else begin 
            n_count = count;
        end
        if (n_count == $pow(2,NBITS) - 1) begin
            cnt_if.overflow = '1;
        end
        // no overflow val just countering till 2** nbits
        // if (n_count == overflow_val) begin
        //     n_of = 1'b1;
        // end else begin
        //     n_of = 1'b0;
        // end
    end 
endmodule
