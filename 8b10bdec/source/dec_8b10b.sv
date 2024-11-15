`timescale 1ns / 10ps

module dec_8b10b(input logic CLK, nRST, input logic[9:0] data_in,
                output logic [7:0] data_out);
    //3b4b dec
    typedef enum logic[3:0] {D0 = 'b0100, D1 = 'b1001, D2 = 'b0101, D3 = 'b0011, D4 = 'b0010, 
                             D5 = 'b1010, D6 = 'b0110, D7 = 'b0001} char_3b_4b;
    logic err_3b_4b;
    always_comb begin
        err_3b_4b = '0;
    case (data_in[9:6])
    D0: data_out[7:5] = '0;
    D1: data_out[7:5] = 'd1;
    D2: data_out[7:5] = 'd2;
    D3: data_out[7:5] = 'd3;
    D4: data_out[7:5] = 'd4;
    D5: data_out[7:5] = 'd5;
    D6: data_out[7:5] = 'd6;
    D7: data_out[7:5] = 'd7;
    default: begin data_out[7:5] = '0;
                err_3b_4b = '1;
        end
    endcase 
    end

    //5b6b dec
 
typedef enum logic[5:0] {
    D5b0  = 'b011000, D5b1  = 'b100010, D5b2  = 'b010010, D5b3  = 'b110001,
    D5b4  = 'b001010, D5b5  = 'b101001, D5b6  = 'b011001, D5b7  = 'b000111,
    D5b8  = 'b000110, D5b9  = 'b100101, D5b10 = 'b010101, D5b11 = 'b110100,
    D5b12 = 'b001101, D5b13 = 'b101100, D5b14 = 'b011100, D5b15 = 'b101000,
    D5b16 = 'b100100, D5b17 = 'b100011, D5b18 = 'b010011, D5b19 = 'b110010,
    D5b20 = 'b001011, D5b21 = 'b101010, D5b22 = 'b011010, D5b23 = 'b000101,
    D5b24 = 'b001100, D5b25 = 'b100110, D5b26 = 'b010110, D5b27 = 'b001001,
    D5b28 = 'b001110, D5b29 = 'b010001, D5b30 = 'b100001, D5b31 = 'b010100
} char_5b_6b;
logic err_5b_6b;

always_comb begin
    err_5b_6b = '0;
    case (data_in[5:0])
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

endmodule