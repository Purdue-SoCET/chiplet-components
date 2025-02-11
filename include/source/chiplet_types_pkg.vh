`ifndef CHIPLET_TYPES_PKG_VH
`define CHIPLET_TYPES_PKG_VH
`timescale 1ns / 10ps
package chiplet_types_pkg;
    // Word
    parameter WORD_W    = 32;
    parameter WBYTES    = WORD_W/8;
    parameter PKT_MAX_LENGTH = 131; // long write: head+address+128 words+crc
    parameter PKT_LENGTH_WIDTH = $clog2(PKT_MAX_LENGTH);

    typedef logic [WORD_W-1:0] word_t;
    typedef logic [4:0] node_id_t;
    typedef logic [1:0] pkt_id_t;

    typedef enum logic [3:0] {
        FMT_LONG_READ   = 4'h0,
        FMT_LONG_WRITE  = 4'h1,
        FMT_MEM_RESP    = 4'h2,
        FMT_MSG         = 4'h3,
        FMT_SWITCH_CFG  = 4'h4,
        FMT_SHORT_READ  = 4'h8,
        FMT_SHORT_WRITE = 4'h9
    } format_e;

    // Long Header
    typedef struct packed {
        format_e        format;
        node_id_t       dest;
        logic [7:0]     r0; // Reserved 0
        logic [3:0]     lst_b;
        logic [3:0]     fst_b;
        logic [6:0]     length;
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

    typedef struct packed {
        logic           vc;
        pkt_id_t        id;
        node_id_t       req;
    } flit_metadata_t;

    // Flit Format
    typedef struct packed {
        flit_metadata_t metadata;
        word_t          payload;
    } flit_t;

    function logic [PKT_LENGTH_WIDTH-1:0] expected_num_flits(word_t flit);
        long_hdr_t long_hdr; 
        short_hdr_t short_hdr;
        resp_hdr_t resp_hdr;
        msg_hdr_t msg_hdr;
    begin
        long_hdr = long_hdr_t'(flit);
        short_hdr = short_hdr_t'(flit);
        resp_hdr = resp_hdr_t'(flit);
        msg_hdr = msg_hdr_t'(flit);
        casez (long_hdr.format)
            FMT_LONG_READ : begin
                expected_num_flits = 3; // header + address + crc
            end
            FMT_LONG_WRITE : begin
                expected_num_flits = 3 + // header + address + crc
                    (|long_hdr.length ? long_hdr.length : 128); // data
            end
            FMT_MEM_RESP : begin
                expected_num_flits = 2 + // header + crc
                    (|resp_hdr.length ? resp_hdr.length : 128); // data
            end
            FMT_MSG : begin
                expected_num_flits = 2 + // header + crc
                    (|msg_hdr.length ? msg_hdr.length : 128); // data
            end
            FMT_SWITCH_CFG : begin
                expected_num_flits = 1;
            end
            FMT_SHORT_READ : begin
                expected_num_flits = 2; // header + crc
            end
            FMT_SHORT_WRITE : begin
                expected_num_flits = 2 + // header + crc
                    (|short_hdr.length ? short_hdr.length : 16); // data
            end
            default : expected_num_flits = 0;
        endcase
    end
    endfunction

endpackage
`endif //CHIPLET_TYPES_PKG_VH
