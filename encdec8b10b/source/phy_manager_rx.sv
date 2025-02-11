`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
module phy_manager_rx #(parameter UNROLL_FACTOR = 8, parameter PORTCOUNT = 5) 
        (input logic CLK, input logic nRST, phy_manager_rx_if.mng_rx mngrx_if); 
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

logic crc_done, crc_clear, crc_update;
logic [31:0] crc_in, crc_out; 
socetlib_crc  crc (.CLK(CLK),.nRST(nRST),.clear(crc_clear),
             .update(crc_update),.in(crc_in),.crc_out(crc_out),
             .done(crc_done));


logic cntr_clear, cntr_enable, overflow_flag_cntr; 
logic [7:0] count_out;
socetlib_counter #(.NBITS(8)) cnt (.CLK(CLK),.nRST(nRST),.clear(cntr_clear),
                 .count_enable(cntr_enable),.overflow_val(dec_if.curr_packet_size),.count_out(count_out),
                 .overflow_flag(overflow_flag_cntr));

wrap_dec_8b_10b_if dec_if();
assign dec_if.enc_flit = mngrx_if.enc_flit_rx;
assign dec_if.done = mngrx_if.done_uart_rx;
assign dec_if.comma_length_sel = mngrx_if.comma_length_sel_rx;
assign dec_if.err = mngrx_if.uart_err_rx;
wrap_dec_8b_10b #(.PORTCOUNT(PORTCOUNT)) dec (.CLK(CLK),.nRST(nRST),.dec_if(dec_if));

assign mngrx_if.flit = dec_if.flit;
assign mngrx_if.comma_sel = dec_if.comma_sel;


typedef enum logic [2:0] { INIT,GET_FORMAT, RUN_CRC, CHECK_CRC, ERR} state_t;
state_t state, n_state;


always_ff @(posedge CLK, negedge nRST) begin
    if(~nRST) begin
        state <= INIT;
    end
    else begin
        state <= n_state;
    end
end

always_comb begin
    n_state = state;
    case (state) 
        INIT: begin 
            if (dec_if.err) begin
                n_state = ERR;
            end
            else if (dec_if.done_out &&  count_out == dec_if.curr_packet_size) begin
                n_state = CHECK_CRC;
            end
            else if (dec_if.done_out) begin
                n_state = RUN_CRC;            
            end
        end
        RUN_CRC: begin 
            if (dec_if.err) begin
                n_state = ERR;
            end
            if (crc_done) begin
                n_state = INIT;
            end
        end
        CHECK_CRC: begin 
            n_state = INIT;
        end
        ERR: begin
            if (dec_if.done_out) begin
                n_state = RUN_CRC; 
            end
         end
        default: begin end
    endcase
end


always_comb begin

    crc_clear = '0;
    crc_update = '0;
    mngrx_if.done_out = '0;
     mngrx_if.crc_corr = '0;
      mngrx_if.err_out = '0;
    cntr_clear = '0;
    cntr_enable = '0;
    mngrx_if.packet_done = '0;
    crc_in = dec_if.flit.payload;
    case (state)    
        INIT: begin
            if (dec_if.done_out && ~(count_out == dec_if.curr_packet_size)) begin
                crc_update = '1;
            end
         end
        RUN_CRC: begin 
            crc_update = '1;
            crc_in = dec_if.flit.payload;
            if (dec_if.err_out) begin
                crc_clear = '1;
                cntr_clear = '1;
                crc_update = '0;
            end
            else if (crc_done) begin
                mngrx_if.done_out = '1;
                cntr_enable = '1;
                crc_update = '0;
            end
        end
        CHECK_CRC: begin 
            mngrx_if.done_out = '1;
            mngrx_if.crc_corr = crc_out == dec_if.flit.payload;
            crc_clear = '1;
            cntr_clear = '1;
            mngrx_if.packet_done = '1;
        end
        ERR: begin 
            mngrx_if.err_out = '1;
            crc_clear = '1;
        end
        default: begin

        end
    endcase
end
endmodule