`timescale 1ns / 10ps
`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"

module dec_8b10b(
    input logic[9:0] data_in,
    output logic [7:0] data_out,
    output logic err
);
    import phy_types_pkg::*;

    //3b4b dec
    logic err_3b_4b;
    always_comb begin
        err_3b_4b = '0;
        case (char_3b_4b'(data_in[9:6]))
            D3b0: data_out[7:5] = '0;
            D3b1: data_out[7:5] = 'd1;
            D3b2: data_out[7:5] = 'd2;
            D3b3: data_out[7:5] = 'd3;
            D3b4: data_out[7:5] = 'd4;
            D3b5: data_out[7:5] = 'd5;
            D3b6: data_out[7:5] = 'd6;
            D3b7: data_out[7:5] = 'd7;
            default: begin
                data_out[7:5] = '0;
                err_3b_4b = '1;
            end
        endcase
    end

    logic err_5b_6b;
    always_comb begin
        err_5b_6b = '0;
        case (char_5b_6b'(data_in[5:0]))
            D5b0: data_out[4:0] = 'd0;
            D5b1: data_out[4:0] = 'd1;
            D5b2: data_out[4:0] = 'd2;
            D5b3: data_out[4:0] = 'd3;
            D5b4: data_out[4:0] = 'd4;
            D5b5: data_out[4:0] = 'd5;
            D5b6: data_out[4:0] = 'd6;
            D5b7: data_out[4:0] = 'd7;
            D5b8: data_out[4:0] = 'd8;
            D5b9: data_out[4:0] = 'd9;
            D5b10: data_out[4:0] = 'd10;
            D5b11: data_out[4:0] = 'd11;
            D5b12: data_out[4:0] = 'd12;
            D5b13: data_out[4:0] = 'd13;
            D5b14: data_out[4:0] = 'd14;
            D5b15: data_out[4:0] = 'd15;
            D5b16: data_out[4:0] = 'd16;
            D5b17: data_out[4:0] = 'd17;
            D5b18: data_out[4:0] = 'd18;
            D5b19: data_out[4:0] = 'd19;
            D5b20: data_out[4:0] = 'd20;
            D5b21: data_out[4:0] = 'd21;
            D5b22: data_out[4:0] = 'd22;
            D5b23: data_out[4:0] = 'd23;
            D5b24: data_out[4:0] = 'd24;
            D5b25: data_out[4:0] = 'd25;
            D5b26: data_out[4:0] = 'd26;
            D5b27: data_out[4:0] = 'd27;
            D5b28: data_out[4:0] = 'd28;
            D5b29: data_out[4:0] = 'd29;
            D5b30: data_out[4:0] = 'd30;
            D5b31: data_out[4:0] = 'd31;
            default: begin
                data_out[4:0] = '0;
                err_5b_6b = '1;
            end
        endcase
    end
    assign err = err_5b_6b || err_3b_4b;
endmodule
