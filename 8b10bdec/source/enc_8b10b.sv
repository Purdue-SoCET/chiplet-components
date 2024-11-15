`timescale 1ns / 10ps

module enc_8b10b(input logic CLK, nRST, input logic [7:0] data_in,
                output logic [9:0] data_out);
    // 3b/4b encoding
    typedef enum logic[3:0] {D3b0 = 'b0100, D3b1 = 'b1001, D3b2 = 'b0101, D3b3 = 'b0011, 
                             D3b4 = 'b0010, D3b5 = 'b1010, D3b6 = 'b0110, D3b7 = 'b0001} char_3b_4b;
    logic err_3b_4b;

    always_comb begin
        err_3b_4b = '0;
        case (data_in[7:5])
            'd0: data_out[9:6] = D3b0;
            'd1: data_out[9:6] = D3b1;
            'd2: data_out[9:6] = D3b2;
            'd3: data_out[9:6] = D3b3;
            'd4: data_out[9:6] = D3b4;
            'd5: data_out[9:6] = D3b5;
            'd6: data_out[9:6] = D3b6;
            'd7: data_out[9:6] = D3b7;
            default: begin
                data_out[9:6] = '0;
                err_3b_4b = '1;
            end
        endcase
    end

    // 5b/6b encoding
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
            default: begin
                data_out[5:0] = '0;
                err_5b_6b = '1;
            end
        endcase
    end
endmodule