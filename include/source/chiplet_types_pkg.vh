`ifndef CHIPLET_TYPES_PKG_VH
`define CHIPLET_TYPES_PKG_VH
`timescale 1ns / 10ps
package chiplet_types_pkg;
    // Word
    parameter WORD_W    = 32;
    parameter WBYTES    = WORD_W/8;

    typedef logic [WORD_W-1:0] word_t;
    typedef logic [4:0] node_id_t;
    typedef logic [1:0] pkt_id_t;

    typedef enum logic [3:0] {
        FMT_LONG_READ, FMT_LONG_WRITE, FMT_MEM_RESP, FMT_MSG,
        FMT_SWITCH_CFG, FMT_SHORT_READ, FMT_SHORT_WRITE
    } format_e;

    // Long Header
    typedef struct packed {
        format_e        format;
        node_id_t       dest;
        logic [7:0]     r0; // Reserved 0
        logic [3:0]     lst_b;
        logic [3:0]     fst_b;
        logic [6:0]     length;
        logic [29:0]    addr;
        logic [1:0]     r1; // Reserved 0
    } long_hdr_t;

    // Short Header
    typedef struct packed {
        format_e        format;
        node_id_t       dest;
        logic [18:0]    addr;
        logic [3:0]     length;
    } short_hdr_t;

    // Message Header
    typedef struct packed {
        format_e        format;
        node_id_t       dest;
        logic [15:0]    msg_code;
        logic [6:0]     length;
    } msg_hdr_t;

    // Read Response Header
    typedef struct packed {
        format_e        format;
        node_id_t       dest;
        logic [15:0]    r; // Reserved 0
        logic [6:0]     length;
    } resp_hdr_t;

    // Switch configuration header
    typedef struct packed {
        format_e        format;
        node_id_t       dest;
        logic [7:0]     data_hi;
        logic [7:0]     addr;
        logic [6:0]     data_lo;
    } switch_cfg_hdr_t;

    // Flit Format
    typedef struct packed {
        logic           vc;
        pkt_id_t        id;
        node_id_t       req;
        word_t          payload;
    } flit_t;

    
endpackage
`endif //CHIPLET_TYPES_PKG_VH
