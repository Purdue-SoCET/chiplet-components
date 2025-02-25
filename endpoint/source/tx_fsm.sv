`include "chiplet_types_pkg.vh"
`include "switch_if.vh"
`include "tx_fsm_if.sv"

module tx_fsm#(
    parameter NUM_MSGS=4,
    parameter TX_SEND_ADDR=32'h1004,
    parameter DEPTH
)(
    input logic clk, n_rst,
    tx_fsm_if.tx_fsm tx_if,
    switch_if.endpoint switch_if,
    bus_protocol_if.protocol tx_cache_if,
    message_table_if.endpoint msg_if
);
    import chiplet_types_pkg::*;

    typedef enum logic [3:0] {
        IDLE, START_SEND_PKT, SEND_PKT
    } state_e;

    typedef logic [PKT_LENGTH_WIDTH-1:0] length_counter_t;

    state_e state, next_state;
    length_counter_t curr_pkt_length, next_curr_pkt_length, length, next_length;
    logic length_clear, length_done, stop_sending;
    flit_t flit;
    pkt_id_t curr_pkt_id, next_curr_pkt_id;

    socetlib_counter #(
        .NBITS(PKT_LENGTH_WIDTH)
    ) length_counter (
        .CLK(clk),
        .nRST(n_rst),
        .clear(length_clear),
        .count_enable(switch_if.data_ready_in[0]),
        .overflow_val(curr_pkt_length),
        .count_out(length),
        .overflow_flag(length_done)
    );

    socetlib_counter #(
        .NBITS(PKT_LENGTH_WIDTH)
    ) send_counter (
        .CLK(clk),
        .nRST(n_rst),
        .clear(switch_if.buffer_available[0][0]),
        .count_enable(switch_if.data_ready_in[0]),
        .overflow_val(3*DEPTH/4),
        .count_out(),
        .overflow_flag(stop_sending)
    );

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= IDLE;
            curr_pkt_length <= 0;
            curr_pkt_id <= 0;
        end else begin
            state <= next_state;
            curr_pkt_length <= next_curr_pkt_length;
            curr_pkt_id <= next_curr_pkt_id;
        end
    end

    // Next state logic
    always_comb begin
        next_state = state;
        next_curr_pkt_id = curr_pkt_id;
        casez (state)
            IDLE : begin
                if (|msg_if.trigger_send) begin
                    next_state = START_SEND_PKT;
                    for (int i = 0; i < NUM_MSGS; i++) begin
                        if (msg_if.trigger_send[i]) begin
                            /* verilator lint_off WIDTHTRUNC */
                            next_curr_pkt_id = i;
                            /* verilator lint_on WIDTHTRUNC */
                        end
                    end
                end
            end
            START_SEND_PKT : begin
                next_state = SEND_PKT;
            end
            SEND_PKT : begin
                if (length_done) begin
                    next_state = IDLE;
                end
            end
            default : begin end
        endcase
    end

    // State output logic
    always_comb begin
        tx_cache_if.addr = tx_if.pkt_start_addr[curr_pkt_id] + (length * 4);
        tx_cache_if.ren = 0;
        tx_cache_if.wen = 0;
        tx_cache_if.strobe = '0;
        // TODO:
        tx_cache_if.is_burst = '0;
        tx_cache_if.burst_type = '0;
        tx_cache_if.burst_length = 0;
        tx_cache_if.secure_transfer = 0;
        next_curr_pkt_length = curr_pkt_length;
        switch_if.data_ready_in[0] = 0;
        flit = flit_t'(0);
        length_clear = 0;

        casez (state)
            IDLE : begin
                next_curr_pkt_length = '1;
                length_clear = 1;
            end
            START_SEND_PKT : begin
                tx_cache_if.ren = 1;
                next_curr_pkt_length = expected_num_flits(tx_cache_if.rdata);
            end
            SEND_PKT : begin
                switch_if.data_ready_in[0] = !stop_sending && !length_done;
                tx_cache_if.ren = 1;
                flit.metadata.vc = 0;
                flit.metadata.id = curr_pkt_id;
                flit.metadata.req = tx_if.node_id;
                flit.payload = tx_bus_if.rdata;
            end
            default : begin end
        endcase

        switch_if.in[0] = flit;
    end
endmodule
