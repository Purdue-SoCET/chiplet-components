
/*
File is a wrapper for 8b/10b encoding and decoding as well as a predecoder for crc and packet counting


*/
`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
// `include "wrap_dec_8b_10b_if.sv"
module wrap_dec_8b_10b # (parameter PORTCOUNT = 5) 
            (input logic CLK, nRST, wrap_dec_8b_10b_if.dec dec_if
                       );
import phy_types_pkg::*;
import chiplet_types_pkg::*;
flit_t flit_data;
flit_t n_flit;
comma_sel_t n_comma_sel;
logic [PORTCOUNT-1 :0] err_dec;
logic [6:0] n_curr_packet_size;
logic komma_kill;
typedef enum logic [1:0] {LOOK_FOR_START_PACKET, LOOK_FOR_DATA_PACKET, LOOK_FOR_END_PACKET} counter_fsm;
counter_fsm seen_start_comma, n_seen_start_comma;

always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        dec_if.done_out <= '0;
        dec_if.flit <= '0; 
        dec_if.comma_sel <= START_PACKET_SEL;
        dec_if.err_out <= '0;
        dec_if.curr_packet_size <= '0;
        seen_start_comma <= LOOK_FOR_START_PACKET;
    end
    else if (dec_if.done) begin
        dec_if.done_out <= dec_if.done && ~ komma_kill;
        dec_if.flit <= n_flit;
        dec_if.comma_sel <= n_comma_sel;
        dec_if.err_out <= dec_if.err || | err_dec;
        dec_if.curr_packet_size <= n_curr_packet_size;
        seen_start_comma <= n_seen_start_comma ;
    end
    else begin
        dec_if.done_out <= '0;
        dec_if.err_out <= dec_if.err;
    end
end

genvar i;

for (i = 0; i < PORTCOUNT; i= i +1) begin : enc_8b10b_block
    dec_8b10b dec (.data_in(dec_if.enc_flit[((i + 1) * 10 - 1):(i * 10)]),.data_out(flit_data[((i + 1) * 8 - 1):(i * 8)]),.err(err_dec[i]));
end

//get payload size
logic n_payload_size;
long_hdr_t long_hdr;
short_hdr_t short_hdr;
msg_hdr_t msg_hdr;
resp_hdr_t resp_hdr;

//comma selection

always_comb begin
    n_flit = '0;
    komma_kill = '0;
    n_comma_sel = dec_if.comma_sel;
    long_hdr = long_hdr_t'({flit_data.payload, 32'd0});
    short_hdr = short_hdr_t'(flit_data.payload);
    msg_hdr = msg_hdr_t'(flit_data.payload);
    resp_hdr = resp_hdr_t'(flit_data.payload);
    n_curr_packet_size = dec_if.curr_packet_size;
    n_seen_start_comma = seen_start_comma;
    case (dec_if.comma_length_sel) 
    SELECT_COMMA_1_FLIT: begin
        n_curr_packet_size = '0;
        komma_kill = '1;
        case(dec_if.enc_flit.word[9:0])
            START_COMMA:  begin 
                n_comma_sel = START_PACKET_SEL;
                n_seen_start_comma = LOOK_FOR_DATA_PACKET;
            end
            END_COMMA:  begin 
                n_comma_sel = END_PACKET_SEL;
                n_seen_start_comma = LOOK_FOR_START_PACKET;
            end
            default: begin
            end
        endcase
    end
    SELECT_COMMA_2_FLIT: begin
        n_curr_packet_size = '0;
        n_flit.vc = flit_data.payload[7];
        n_flit.id = flit_data.payload[6:5];
        n_flit.req = flit_data.payload[4:0];
        case(dec_if.enc_flit.word[19:10])
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
            ACK_COMMA: begin
                n_comma_sel = ACK_SEL;
            end
            default: begin
            end
        endcase
    end
    SELECT_COMMA_DATA: begin    
        n_flit = flit_data;
        n_comma_sel = DATA_SEL;
        if (seen_start_comma == LOOK_FOR_DATA_PACKET) begin
            n_curr_packet_size = expected_num_flits(flit_data.payload) - 'd1;
        //predecode message package size if reading new packet
        // case (flit_data.payload[31:28])
        //     FMT_LONG_READ: n_curr_packet_size = 'd2;
        //     FMT_SHORT_READ: n_curr_packet_size = 'd1;
        //     FMT_LONG_WRITE: n_curr_packet_size = 'd2 + (long_hdr.length != '0 ? {1'd0, long_hdr.length} : 8'd128);
        //     FMT_MEM_RESP: n_curr_packet_size = 'd1 + (resp_hdr.length !='0 ? {1'd0,resp_hdr.length} : 8'd128); 
        //     FMT_MSG: n_curr_packet_size = 'd1 + (msg_hdr.length != '0 ? {1'd0,msg_hdr.length} : 8'd128); 
        //     FMT_SWITCH_CFG: n_curr_packet_size = 'd1;
        //     FMT_SHORT_WRITE: n_curr_packet_size = 'd1 + (short_hdr.length != '0 ? {4'd0,short_hdr.length} : 8'd16);
        //     default: begin
        //     end
        // endcase
            n_seen_start_comma = LOOK_FOR_END_PACKET;
        end
    end
    default: begin
    end
    endcase
end



endmodule