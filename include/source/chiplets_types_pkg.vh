`ifndef CHIPLETS_TYPES_PKG_VH
`define CHIPLETS_TYPES_PKG_VH

package chiplets_types_pkg;
    // Word
    parameter WORD_W    = 32;
    parameter WBYTES    = WORD_W/8;

    typedef logic [WORD_W-1:0] word_t;

    // Long Header
    typedef struct packed {
        logic [3:0]     format;
        logic [4:0]     dest;
        logic [3:0]     lst_b;
        logic [3:0]     fst_b;
        logic [6:0]     length;
        logic [29:0]    addr;
    } long_hdr_t;

    // Short Header
    typedef struct packed {
        logic [3:0]     format;
        logic [4:0]     dest;
        logic [3:0]     length;
        logic [18:0]    addr;
    } short_hdr_t;

    // Message Header
    typedef struct packed {
        logic [3:0]     format;
        logic [4:0]     dest;
        logic [15:0]    msg_code;
        logic [6:0]     length;
    } msg_hdr_t;

    // Read Response Header
    typedef struct packed {
        logic [3:0]     format;
        logic [4:0]     dest;
        logic [6:0]     length;
    } resp_hdr_t;

    // Flit Format
    typedef struct packed {
        logic           vc;
        logic [1:0]     id;
        logic [4:0]     req;
        logic [31:0]    payload;
    } flit_t;
endpackage
`endif //CHIPLETS_TYPES_PKG_VH
