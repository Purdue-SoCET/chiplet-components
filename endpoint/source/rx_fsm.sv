`include "chiplet_types_pkg.vh"
`include "switch_if.vh"

module rx_fsm#()(
    input logic clk, n_rst,
    input logic overflow, 
    input word_t crc_val,
    output logic fifo_enable, cache_enable,
    output logic [31:0] cache_addr,
    output node_id_t req,
    switch_if.endpoint switch_if,
);
    import chiplet_types_pkg::*;

    typedef enum logic [2:0] {
        IDLE, GET_LENGTH, CRC_CHECK, REQ_EN
    } state_e;

    typedef logic [PKT_LENGTH_WIDTH-1:0] length_counter_t;

    state_e state, next_state;
    length_counter_t curr_pkt_length, next_curr_pkt_length, length, next_length;
    logic length_clear, length_done, stop_sending;
    logic count_enable;
    word_t next_cache_addr;
    // pkt_id_t curr_pkt_id, next_curr_pkt_id;
    // long_hdr_t       long_hdr;
    // short_hdr_t      short_hdr;
    // msg_hdr_t        msg_hdr;
    // resp_hdr_t       resp_hdr;
    // switch_cfg_hdr_t switch_cfg_hdr;

    socetlib_counter #(.NBITS(PKT_LENGTH_WIDTH)) length_counter (
        .CLK(clk),
        .nRST(n_rst),
        .clear(length_clear),
        .count_enable(count_enable),
        .overflow_val(curr_pkt_length),
        .count_out(length),
        .overflow_flag(length_done)
    );

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= IDLE;
            curr_pkt_length <= 0;
            cache_addr <= ;
            // curr_pkt_id <= 0;
        end else begin
            state <= next_state;
            curr_pkt_length <= next_curr_pkt_length;
            cache_addr <= next_cache_addr;
            // curr_pkt_id <= next_curr_pkt_id;
        end
    end

    assign req = switch_if.out[0].req;

    // Next state logic
    always_comb begin
        next_state = state;
        casez (state)
            IDLE : begin
                if(switch_if.data_ready_out[0]) begin
                    next_state = GET_LENGTH;
                end
            end
            GET_LENGTH : begin
                if(length_done)begin
                    next_state = CRC_CHECK;
                end
            end
            CRC_CHECK : begin
                if(crc_val != switch_if.out[0].payload) begin
                    next_state = IDLE;
                end else begin
                    next_state = REQ_EN
                end
            end
            REQ_EN: begin
                next_state = IDLE;
            end
            default : begin end
        endcase
    end

    // State output logic
    always_comb begin
        next_curr_pkt_length = curr_pkt_length;
        count_enable = 0;
        fifo_enable = 0;
        cache_enable = 0;
        length_clear = 0;
        next_cache_addr = cache_addr;
        casez (state)
            IDLE : begin end
            GET_LENGTH : begin
                next_curr_pkt_length = expected_num_flits(switch_if.out[0].payload);
                cache_enable = 1;
                count_enable = switch_if.data_ready_out[0];
                next_cache_addr = cache_addr + 
                //TODO specify cache address
            end
            CRC_CHECK : begin
                if(crc_val != switch_if.out[0].payload) begin
                    next_cache_addr = cache_addr -
                end 
             end
            REQ_EN: begin
                fifo_enable = 1;
                length_clear = 1;
            end
            default : begin end
        endcase 
    end
endmodule
