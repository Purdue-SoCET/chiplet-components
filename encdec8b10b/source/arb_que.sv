`timescale 1ns / 10ps


module arb_que#(NBITS = 8)(input logic CLK, nRST, arb_que_if.que que_if);
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    logic [15:0][(NBITS - 1) : 0] que;
    logic [15:0][(NBITS - 1) : 0] n_que;
    assign que_if.que_out = que[0];

    always_ff @(posedge CLK, negedge nRST) begin
        if (nRST == 1'b0) begin
            que <= 0;
        end
        else begin
            que <= n_que;
        end
    end

    always_comb begin
        n_que = que;
        if (que_if.clear == 1'b1) begin
            n_que = '0; 
        end else  if (que_if.en && que_if.dec) begin
            n_que = {8'b0,que[14:0]};
            n_que[que_if.count_in] = que_if.que_in;
        end 
        else if (que_if.en) begin
            if (que_if.count_in + 1 > (2** NBITS - 1))
                n_que = que; //add send nack case future work
            else 
                n_que[que_if.count_in] = que_if.que_in;
        end
        else if (que_if.dec) begin
            n_que = {8'b0,que[14:0]};
        end
    end
endmodule