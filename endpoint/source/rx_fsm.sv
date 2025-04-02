`include "chiplet_types_pkg.vh"

module rx_fsm (
    input logic clk, n_rst,
    rx_fsm_if.rx_fsm rx_if,
    endpoint_if.rx_fsm endpoint_if
);
    import chiplet_types_pkg::*;

    typedef enum logic [2:0] {
        IDLE, HEADER, CRC_WAIT, CRC_CHECK, BODY, REQ_EN
    } state_e;

    typedef logic [PKT_LENGTH_WIDTH-1:0] length_counter_t;

    state_e state, next_state;
    length_counter_t curr_pkt_length, next_curr_pkt_length, length, next_length;
    logic length_clear, length_done, stop_sending;
    logic count_enable, done, clear_crc, crc_update;
    chiplet_word_t crc_val;

    socetlib_crc CRC_CHECKER(
        .CLK(clk),
        .nRST(n_rst),
        .clear(clear_crc),
        .update(crc_update),
        .in(endpoint_if.out.payload),
        .crc_out(crc_val),
        .done(done)
    );

    socetlib_counter #(
        .NBITS(PKT_LENGTH_WIDTH)
    ) length_counter (
        .CLK(clk),
        .nRST(n_rst),
        .clear(length_clear),
        .count_enable(count_enable),
        .overflow_val(curr_pkt_length - 1),
        .count_out(length),
        .overflow_flag(length_done)
    );

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= IDLE;
            curr_pkt_length <= 0;
        end else begin
            state <= next_state;
            curr_pkt_length <= next_curr_pkt_length;
        end
    end

    assign rx_if.metadata = {endpoint_if.out.metadata.id, endpoint_if.out.metadata.req};

    // Next state logic
    always_comb begin
        next_state = state;
        casez (state)
            IDLE : begin
                if(endpoint_if.data_ready_out) begin
                    next_state = HEADER;
                end
            end
            HEADER : begin
                next_state = CRC_WAIT;
            end
            CRC_WAIT : begin
                if (!rx_if.rx_fifo_full) begin
                    if(done && !length_done) begin
                        next_state = BODY;
                    end
                    else if(done && length_done) begin
                        next_state = CRC_CHECK;
                    end
                end
            end
            BODY : begin
                if(endpoint_if.data_ready_out && length_done) begin
                    next_state = CRC_CHECK;
                end else if (endpoint_if.data_ready_out) begin
                    next_state = CRC_WAIT;
                end
            end
            CRC_CHECK : begin
                if (!rx_if.rx_fifo_full) begin
                    if(crc_val != endpoint_if.out.payload) begin
                        next_state = IDLE;
                    end else begin
                        next_state = REQ_EN;
                    end
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
        rx_if.metadata_fifo_wen = 0;
        length_clear = 0;
        clear_crc = 0;
        crc_update = 0;
        endpoint_if.packet_sent = 0;
        endpoint_if.credit_granted = 0;
        rx_if.rx_fifo_wen = 0;

        casez (state)
            IDLE : begin
                clear_crc = 1;
             end
            HEADER : begin
                next_curr_pkt_length = expected_num_flits(endpoint_if.out.payload);
            end
            CRC_WAIT : begin
                crc_update = endpoint_if.data_ready_out && !done && !rx_if.rx_fifo_full;
                if (done && !rx_if.rx_fifo_full) begin
                    rx_if.rx_fifo_wen = 1;
                    endpoint_if.packet_sent = 1;
                    endpoint_if.credit_granted[endpoint_if.out.metadata.vc] = 1;
                    count_enable = 1;
                end
            end
            BODY : begin end
            CRC_CHECK : begin
                endpoint_if.packet_sent = 1;
                endpoint_if.credit_granted[endpoint_if.out.metadata.vc] = 1;
                if(crc_val == endpoint_if.out.payload && !rx_if.rx_fifo_full) begin
                    rx_if.rx_fifo_wen = 1;
                end
             end
            REQ_EN: begin
                if(!rx_if.metadata_full) begin
                    rx_if.metadata_fifo_wen = 1;
                    length_clear = 1;
                end
            end
            default : begin end
        endcase
    end
endmodule
