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
`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
module wrap_dec_8b_10b # (parameter PORTCOUNT = 5) 
            (input logic CLK, nRST, wrap_dec_8b_10b_if.dec dec_if
                       );
import phy_types_pkg::*;
import chiplet_types_pkg::*;
flit_t flit_data;
flit_t n_flit;
comma_sel_t n_comma_sel;
logic [PORTCOUNT-1 :0] err_dec;
always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        dec_if.done_out <= '0;
        dec_if.flit <= '0; 
        dec_if.comma_sel <= START_PACKET_SEL;
        dec_if.err_out <= '0;
    end
    else if (dec_if.done) begin
        dec_if.done_out <= dec_if.done;
        dec_if.flit <= n_flit;
        dec_if.comma_sel <= n_comma_sel;
        dec_if.err_out <= dec_if.err || | err_dec;
    end
    else begin
        dec_if.done_out <= '0;
        dec_if.flit <= n_flit;
        dec_if.comma_sel <= n_comma_sel;
        dec_if.err_out <= dec_if.err;
    end
end

genvar i;

for (i = 0; i < PORTCOUNT; i= i +1) begin : enc_8b10b_block
    dec_8b10b dec (.CLK(CLK),.nRST(nRST),.data_in(dec_if.enc_flit[((i + 1) * 10 - 1):(i * 10)]),.data_out(flit_data[((i + 1) * 8 - 1):(i * 8)]),.err(err_dec[i]));
end

//comma selection
always_comb begin
    n_flit = '0;
    n_comma_sel = START_PACKET_SEL;
    case (dec_if.comma_length_sel) 
    SELECT_COMMA_1_FLIT: begin
        case(flit_data.payload[9:0])
            START_COMMA:  begin 
                n_comma_sel = START_PACKET_SEL;
            end
            END_COMMA:  begin 
                n_comma_sel = END_PACKET_SEL;
            end
            ACK_COMMA: begin     
                n_comma_sel = ACK_SEL;
            end
            default: begin
            end
        endcase
    end
    SELECT_COMMA_2_FLIT: begin
        n_flit.vc = flit_data.payload[7];
        n_flit.id = flit_data.payload[6:5];
        n_flit.req = flit_data.payload[4:0];
        case(flit_data.payload[19:10])
            RESEND_PACKET0_COMMA:  begin 
                n_comma_sel = RESEND_PACKET0_SEL;
            end
            RESEND_PACKET1_COMMA:  begin 
                n_comma_sel = RESEND_PACKET1_SEL;
            end
            RESEND_PACKET2_COMMA: begin     
                n_comma_sel = RESEND_PACKET2_SEL;
            end
            RESEND_PACKET3_COMMA: begin     
                n_comma_sel = RESEND_PACKET3_SEL;
            end
            NACK_COMMA: begin
                n_comma_sel = NACK_SEL;
            end
            default: begin
            end
        endcase
    end
    SELECT_COMMA_DATA: begin
        n_flit = flit_data;
    end
    default: begin
    end
    endcase
end



endmodule