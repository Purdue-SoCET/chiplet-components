
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
logic [PKT_LENGTH_WIDTH-1:0] n_curr_packet_size;
logic done_out_n, err_in_order,err_in_comma;
logic [1:0] n_grt_cred;
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
    else  begin
        dec_if.done_out <= dec_if.done;
        dec_if.flit <= n_flit;
        dec_if.comma_sel <= n_comma_sel;
        dec_if.err_out <= dec_if.err || (( | err_dec || err_in_order) && dec_if.done);
        dec_if.curr_packet_size <= n_curr_packet_size;
        seen_start_comma <= n_seen_start_comma ;
    end
end

genvar i;
//instantiate 5 decoders for input data
generate
for (i = 0; i < PORTCOUNT; i= i +1) begin : enc_8b10b_block
    dec_8b10b dec (.data_in(dec_if.enc_flit[((i + 1) * 10 - 1):(i * 10)]),.data_out(flit_data[((i + 1) * 8 - 1):(i * 8)]),.err(err_dec[i]));
end
endgenerate

//get payload size
logic n_payload_size;
long_hdr_t long_hdr;
short_hdr_t short_hdr;
msg_hdr_t msg_hdr;
resp_hdr_t resp_hdr;

//comma selection
always_comb begin
    n_flit = dec_if.flit;
    err_in_comma = '0;
    n_comma_sel = dec_if.comma_sel;
    long_hdr = long_hdr_t'({flit_data.payload, 32'd0});
    short_hdr = short_hdr_t'(flit_data.payload);
    msg_hdr = msg_hdr_t'(flit_data.payload);
    resp_hdr = resp_hdr_t'(flit_data.payload);
    if (dec_if.done) begin
        done_out_n = '1;
        case (dec_if.comma_length_sel) 
        SELECT_COMMA_1_FLIT: begin
            case(dec_if.enc_flit.word[9:0])
                START_COMMA:  begin 
                    n_comma_sel = START_PACKET_SEL;
                end
                END_COMMA:  begin 
                    n_comma_sel = END_PACKET_SEL;
                end
                GRTCRED0_COMMA: begin
                    n_comma_sel = GRTCRED0_SEL;
                end
                GRTCRED1_COMMA: begin 
                    n_comma_sel = GRTCRED1_SEL;
                end
                default: begin
                    err_in_comma = '1;
                end
            endcase
        end
        SELECT_COMMA_2_FLIT: begin
            n_flit.metadata.vc = flit_data.payload[7];
            n_flit.metadata.id = flit_data.payload[6:5];
            n_flit.metadata.req = flit_data.payload[4:0];
            case(dec_if.enc_flit.word[19:10])
                ACK_COMMA: begin
                    n_comma_sel = ACK_SEL;
                end
                default: begin
                    err_in_comma = '1;
                end
            endcase
        end
        SELECT_COMMA_DATA: begin    
            n_flit = flit_data;
            n_comma_sel = DATA_SEL;
        end
        default: begin
        end
        endcase
    end
end

always_comb begin
    err_in_order = '0;
    n_seen_start_comma = seen_start_comma;
    case (seen_start_comma) 
        LOOK_FOR_START_PACKET: begin
            if (dec_if.enc_flit.word[9:0] == START_COMMA && dec_if.comma_length_sel == SELECT_COMMA_1_FLIT && dec_if.done) begin
                n_seen_start_comma = LOOK_FOR_DATA_PACKET;
            end
            else if ( dec_if.comma_length_sel == SELECT_COMMA_DATA && dec_if.done) begin
                err_in_order = '1;
            end
        end
        LOOK_FOR_DATA_PACKET: begin
            if (dec_if.comma_length_sel == SELECT_COMMA_DATA && dec_if.done) begin
                n_seen_start_comma = LOOK_FOR_END_PACKET;
            end
            else if ( (dec_if.comma_length_sel == SELECT_COMMA_1_FLIT || dec_if.comma_length_sel == SELECT_COMMA_2_FLIT) && dec_if.done) begin
                err_in_order = '1;
            end
        end
        LOOK_FOR_END_PACKET: begin
            if (dec_if.comma_length_sel == SELECT_COMMA_1_FLIT && dec_if.done && dec_if.enc_flit.word[9:0] == END_COMMA) begin
                n_seen_start_comma = LOOK_FOR_START_PACKET;
            end
            else if (( dec_if.comma_length_sel == SELECT_COMMA_2_FLIT && dec_if.done) || dec_if.comma_length_sel == SELECT_COMMA_1_FLIT && dec_if.done ) begin
                if (dec_if.enc_flit.word[9:0] == START_COMMA) begin
                    n_seen_start_comma = LOOK_FOR_DATA_PACKET;
                end
                err_in_order = '1;
            end
        end
        default : begin end
    endcase
end

always_comb begin
    n_curr_packet_size =  dec_if.curr_packet_size;
    if (seen_start_comma == LOOK_FOR_DATA_PACKET) begin
        n_curr_packet_size = expected_num_flits(flit_data.payload) - 'd1;
    end
    else if (dec_if.comma_length_sel == SELECT_COMMA_1_FLIT || dec_if.comma_length_sel == SELECT_COMMA_2_FLIT) begin
        n_curr_packet_size = '0;
    end
end


endmodule
