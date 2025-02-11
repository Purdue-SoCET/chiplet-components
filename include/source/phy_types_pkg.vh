`ifndef PHY_TYPES_PKG_VH
`define PHY_TYPES_PKG_VH
`timescale 1ns / 10ps
package phy_types_pkg;
    parameter ENC_WORD_W = 40;

    //comma length io for uart
    typedef enum logic [1:0] {
        NADA = '0,
        SELECT_COMMA_1_FLIT = 'd1,
        SELECT_COMMA_2_FLIT = 'd2,
        SELECT_COMMA_DATA = 'd3
    } comma_length_sel_t;

    //comma select input for 8b10b
    typedef enum logic [3:0] {
        START_PACKET_SEL,
        END_PACKET_SEL,
        RESEND_PACKET0_SEL,
        RESEND_PACKET1_SEL,
        RESEND_PACKET2_SEL,
        RESEND_PACKET3_SEL,
        ACK_SEL,
        NACK_SEL,
        DATA_SEL,
        NADA_SEL // for debug purposes
    } comma_sel_t;

    //comma definitions
    typedef enum logic [9:0] {
        START_COMMA = 10'b1100001011,
        END_COMMA = 10'b1100000110,
        RESEND_PACKET0_COMMA = 10'b1100001010,
        RESEND_PACKET1_COMMA = 10'b1100001100,
        RESEND_PACKET2_COMMA = 10'b1100001101,
        RESEND_PACKET3_COMMA = 10'b1100000101,
        ACK_COMMA = 10'b1100001001,
        NACK_COMMA  = 10'b1100000111
    } comma_t;

    //encoded word
    typedef logic [(ENC_WORD_W - 1):0] enc_word_t;

    //encoded flit type
    typedef struct packed {
        logic [9:0] meta_data;
        enc_word_t word;
    } flit_enc_t;

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


    typedef enum logic[3:0] {
        D3b0 = 'b0100,
        D3b1 = 'b1001,
        D3b2 = 'b0101,
        D3b3 = 'b0011,
        D3b4 = 'b0010,
        D3b5 = 'b1010,
        D3b6 = 'b0110,
        D3b7 = 'b0001
    } char_3b_4b;

endpackage
`endif //CHIPLET_TYPES_PKG_VH
