// parameter ENC_WORD_W = 40;
// typedef enum logic [1:0] {SELECT_COMMA_1_FLIT,SELECT_COMMA_2_FLIT,SELECT_COMMA_DATA} comma_length_sel_t;
// typedef enum logic [3:0] {START_PACKET_SEL, END_PACKET_SEL,RESEND_PACKET0_SEL,RESEND_PACKET1_SEL
//                           RESEND_PACKET2_SEL, RESEND_PACKET3_SEL, ACK_SEL, NACK_SEL, DATA_SEL} comma_sel_t;
// typedef enum logic [9:0] {START_COMMA = , END_COMMA = , RESEND_PACKET0_COMMA = , RESEND_PACKET1_COMMA = ,
//                           RESEND_PACKET2_SEL, RESEND_PACKET3_SEL, ACK_COMMA, NACK_COMMA} comma_t;
// typedef logic [(ENC_WORD_W - 1):0] enc_word_t;
// typedef struct packed {
//     logic [9:0] header;
//     enc_word_t word;
// } flit_enc_t;
`timescale 1ns / 10ps
`include "chiplet_types_pkg.vh"
// `include "wrap_enc_8b_10b_if.sv"
`include "phy_types_pkg.vh"
module wrap_enc_8b_10b #(parameter PORTCOUNT = 5) 
            (input logic CLK, nRST, wrap_enc_8b_10b_if.enc enc_if);
import phy_types_pkg::*;
import chiplet_types_pkg::*;
flit_enc_t flit_norm;
flit_enc_t n_flit;
comma_length_sel_t n_comma_length_sel_out;

always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        enc_if.start_out <= '0;
        enc_if.flit_out <= '0;
        enc_if.comma_length_sel_out <= SELECT_COMMA_1_FLIT;
    end
    else if (enc_if.start) begin
        enc_if.start_out <= '1;
        enc_if.flit_out <= n_flit;
        enc_if.comma_length_sel_out <= n_comma_length_sel_out;
    end
    else begin
        enc_if.start_out <= '0;
        // enc_if.flit_out <= n_flit;
        // enc_if.comma_length_sel_out <= SELECT_COMMA_1_FLIT;
    end
end

genvar i;
for (i = 0; i < PORTCOUNT; i= i +1) begin : enc_8b10b_block
    enc_8b10b enc (.data_in(enc_if.flit[((i + 1) * 8 - 1):(i * 8)]),.data_out(flit_norm[((i + 1) * 10 - 1):(i * 10)]));
end

//comma selection
always_comb begin
    n_flit = '0;
    n_comma_length_sel_out = SELECT_COMMA_1_FLIT;
    case (enc_if.comma_sel) 
    START_PACKET_SEL: begin
        n_flit =  {START_COMMA, {40{1'b1}}}; 
        n_comma_length_sel_out = SELECT_COMMA_1_FLIT;
    end
     END_PACKET_SEL:  begin
        n_flit =  {END_COMMA, {40{1'b1}}}; 
        n_comma_length_sel_out = SELECT_COMMA_1_FLIT;
        end
    RESEND_PACKET0_SEL: begin 
        n_flit = {RESEND_PACKET0_COMMA,flit_norm.meta_data, {30{1'b1}}};
        n_comma_length_sel_out = SELECT_COMMA_2_FLIT;
        end
    RESEND_PACKET1_SEL: begin
        n_flit = {RESEND_PACKET1_COMMA,flit_norm.meta_data, {30{1'b1}}};
        n_comma_length_sel_out = SELECT_COMMA_2_FLIT;
    end
    RESEND_PACKET2_SEL: begin
        n_flit = {RESEND_PACKET2_COMMA,flit_norm.meta_data, {30{1'b1}}};
        n_comma_length_sel_out = SELECT_COMMA_2_FLIT;
    end
    RESEND_PACKET3_SEL: begin
        n_flit = {RESEND_PACKET3_COMMA,flit_norm.meta_data, {30{1'b1}}};
        n_comma_length_sel_out = SELECT_COMMA_2_FLIT;
    end
    ACK_SEL: begin
        n_flit = {ACK_COMMA,flit_norm.meta_data, {30{1'b1}}};
        n_comma_length_sel_out = SELECT_COMMA_2_FLIT;
    end
    DATA_SEL:  begin 
        n_flit = flit_norm; 
        n_comma_length_sel_out = SELECT_COMMA_DATA;
        end
    NACK_SEL: begin
        n_flit = {NACK_COMMA,flit_norm.meta_data, {30{1'b1}}};
        n_comma_length_sel_out = SELECT_COMMA_2_FLIT;
    end
    default: begin
    end
    endcase 
end



endmodule