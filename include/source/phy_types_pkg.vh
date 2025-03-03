`ifndef PHY_TYPES_PKG_VH
`define PHY_TYPES_PKG_VH
`timescale 1ns / 10ps
package phy_types_pkg;
    parameter ENC_WORD_W = 40;

    //comma length io for uart
    typedef enum logic [1:0] {
        NADA = 2'd0, //for debug purposes on final version can be removed
        SELECT_COMMA_1_FLIT = 2'd1,
        SELECT_COMMA_2_FLIT = 2'd2,
        SELECT_COMMA_DATA = 2'd3
    } comma_length_sel_t;

    //comma select input for 8b10b
    typedef enum logic [3:0] {
        START_PACKET_SEL,
        END_PACKET_SEL,
        GRTCRED0_SEL,
        GRTCRED1_SEL,
        ACK_SEL,
        DATA_SEL,
        NADA_SEL // for debug purposes
    } comma_sel_t;

    //comma definitions
    typedef enum logic [9:0] {
        START_COMMA = 10'b1100001011,
        END_COMMA = 10'b1100000110,
        GRTCRED0_COMMA = 10'b1100001010,
        GRTCRED1_COMMA = 10'b1100001100,
        ACK_COMMA = 10'b1100001001
    } comma_t;

    //encoded word
    typedef logic [(ENC_WORD_W - 1):0] enc_word_t;

    //encoded flit type
    typedef struct packed {
        logic [9:0] meta_data;
        enc_word_t word;
    } flit_enc_t;

    typedef enum logic[5:0] {
        D5b0  = 6'b011000, D5b1  = 6'b100010, D5b2  = 6'b010010, D5b3  = 6'b110001,
        D5b4  = 6'b001010, D5b5  = 6'b101001, D5b6  = 6'b011001, D5b7  = 6'b000111,
        D5b8  = 6'b000110, D5b9  = 6'b100101, D5b10 = 6'b010101, D5b11 = 6'b110100,
        D5b12 = 6'b001101, D5b13 = 6'b101100, D5b14 = 6'b011100, D5b15 = 6'b101000,
        D5b16 = 6'b100100, D5b17 = 6'b100011, D5b18 = 6'b010011, D5b19 = 6'b110010,
        D5b20 = 6'b001011, D5b21 = 6'b101010, D5b22 = 6'b011010, D5b23 = 6'b000101,
        D5b24 = 6'b001100, D5b25 = 6'b100110, D5b26 = 6'b010110, D5b27 = 6'b001001,
        D5b28 = 6'b001110, D5b29 = 6'b010001, D5b30 = 6'b100001, D5b31 = 6'b010100
    } char_5b_6b;


    typedef enum logic[3:0] {
        D3b0 = 4'b0100,
        D3b1 = 4'b1001,
        D3b2 = 4'b0101,
        D3b3 = 4'b0011,
        D3b4 = 4'b0010,
        D3b5 = 4'b1010,
        D3b6 = 4'b0110,
        D3b7 = 4'b0001
    } char_3b_4b;

endpackage
`endif //CHIPLET_TYPES_PKG_VH
