`include "chiplet_types_pkg.vh"
`include "switch_if.vh"

module rx_fsm#()(
    input logic clk, n_rst,
    switch_if.endpoint switch_if,
);
    import chiplet_types_pkg::*;

    typedef enum logic [2:0] {
        IDLE, GET_LENGTH, CRC_WAIT
    } state_e;

    typedef logic [PKT_LENGTH_WIDTH-1:0] length_counter_t;

    state_e state, next_state;
    length_counter_t curr_pkt_length, next_curr_pkt_length, length, next_length;
    logic length_clear, length_done, stop_sending;
    logic count_enable;
    flit_t flit;
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
            // curr_pkt_id <= 0;
        end else begin
            state <= next_state;
            curr_pkt_length <= next_curr_pkt_length;
            // curr_pkt_id <= next_curr_pkt_id;
        end
    end

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
                next_state = CRC_WAIT;
            end
            CRC_WAIT : begin
                if(length_done) begin
                    next_state = IDLE;
                end
            end
            default : begin end
        endcase
    end

    // State output logic
    always_comb begin
        next_curr_pkt_length = curr_pkt_length;
        count_enable = 0;
        casez (state)
            IDLE : begin end
            GET_LENGTH : begin
                next_curr_pkt_length = expected_num_flits(switch_if.out);
            end
            CRC_WAIT : begin
                count_enable = switch_if.data_ready_out[0];
            end
            default : begin end
        endcase 
    end
endmodule
