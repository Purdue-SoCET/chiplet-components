`timescale 1ns / 10ps
`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"

module enc_8b10b(
    input logic [7:0] data_in,
    output logic [9:0] data_out
);
    import phy_types_pkg::*;

    always_comb begin
        case (data_in[7:5])
            'd0: data_out[9:6] = D3b0;
            'd1: data_out[9:6] = D3b1;
            'd2: data_out[9:6] = D3b2;
            'd3: data_out[9:6] = D3b3;
            'd4: data_out[9:6] = D3b4;
            'd5: data_out[9:6] = D3b5;
            'd6: data_out[9:6] = D3b6;
            'd7: data_out[9:6] = D3b7;
        endcase
    end

    // 5b/6b encoding
    always_comb begin
        case (data_in[4:0])
            'd0: data_out[5:0] = D5b0;
            'd1: data_out[5:0] = D5b1;
            'd2: data_out[5:0] = D5b2;
            'd3: data_out[5:0] = D5b3;
            'd4: data_out[5:0] = D5b4;
            'd5: data_out[5:0] = D5b5;
            'd6: data_out[5:0] = D5b6;
            'd7: data_out[5:0] = D5b7;
            'd8: data_out[5:0] = D5b8;
            'd9: data_out[5:0] = D5b9;
            'd10: data_out[5:0] = D5b10;
            'd11: data_out[5:0] = D5b11;
            'd12: data_out[5:0] = D5b12;
            'd13: data_out[5:0] = D5b13;
            'd14: data_out[5:0] = D5b14;
            'd15: data_out[5:0] = D5b15;
            'd16: data_out[5:0] = D5b16;
            'd17: data_out[5:0] = D5b17;
            'd18: data_out[5:0] = D5b18;
            'd19: data_out[5:0] = D5b19;
            'd20: data_out[5:0] = D5b20;
            'd21: data_out[5:0] = D5b21;
            'd22: data_out[5:0] = D5b22;
            'd23: data_out[5:0] = D5b23;
            'd24: data_out[5:0] = D5b24;
            'd25: data_out[5:0] = D5b25;
            'd26: data_out[5:0] = D5b26;
            'd27: data_out[5:0] = D5b27;
            'd28: data_out[5:0] = D5b28;
            'd29: data_out[5:0] = D5b29;
            'd30: data_out[5:0] = D5b30;
            'd31: data_out[5:0] = D5b31;
        endcase
    end
endmodule 
