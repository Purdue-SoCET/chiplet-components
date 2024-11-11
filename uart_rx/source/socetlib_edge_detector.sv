// File name:   edge_detector.sv
// Created:     4/16/2015
// Author:      John Skubic
// Version:     1.0 
// Description: Edge detector, added to socetlib by Cole Nelson 8/14/22 
//	

module socetlib_edge_detector #(
    parameter WIDTH = 1
)
(
    input logic CLK, nRST, 
    input logic [WIDTH - 1:0] signal,
    output logic [WIDTH - 1:0] pos_edge, neg_edge
);

    logic [WIDTH - 1 : 0] signal_r;

    //flip flop behavior
    always_ff @ (posedge CLK, negedge nRST) begin
        if(~nRST)
            signal_r <= signal;
        else 
            signal_r <= signal;
    end

    //output logic
    assign pos_edge = signal & ~signal_r;
    assign neg_edge = ~signal & signal_r;

endmodule