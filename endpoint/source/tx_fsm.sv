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
    endpoint_if.tx_fsm endpoint_if,
    bus_protocol_if.protocol tx_cache_if,
    message_table_if.endpoint msg_if
);
    import chiplet_types_pkg::*;

    typedef enum logic [3:0] {
        IDLE, START_SEND_PKT, SEND_PKT, CRC
    } state_e;

    typedef logic [PKT_LENGTH_WIDTH-1:0] length_counter_t;

    long_hdr_t long_hdr; 
    state_e state, next_state;
    length_counter_t curr_pkt_length, next_curr_pkt_length, length, next_length;
    format_e curr_pkt_fmt, next_curr_pkt_fmt;
    logic length_clear, length_done, stop_sending, crc_done, crc_update;
    logic [31:0] crc_out, crc_in;
    flit_t flit;
    pkt_id_t curr_pkt_id, next_curr_pkt_id;

    socetlib_counter #(
        .NBITS(PKT_LENGTH_WIDTH)
    ) length_counter (
        .CLK(clk),
        .nRST(n_rst),
        .clear(length_clear),
        .count_enable(endpoint_if.data_ready_in),
        .overflow_val(curr_pkt_length),
        .count_out(length),
        .overflow_flag(length_done)
    );

    socetlib_counter #(
        .NBITS(PKT_LENGTH_WIDTH)
    ) send_counter (
        .CLK(clk),
        .nRST(n_rst),
        .clear(endpoint_if.buffer_available[0]),
        .count_enable(endpoint_if.data_ready_in),
        .overflow_val(3*DEPTH/4),
        .count_out(),
        .overflow_flag(stop_sending)
    );

    socetlib_crc CRC_GEN (
        .CLK(clk),
        .nRST(n_rst),
        .clear(length_clear),
        .update(crc_update),
        .in(crc_in),
        .crc_out(crc_out),
        .done(crc_done)
    );

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            state <= IDLE;
            curr_pkt_length <= 0;
            curr_pkt_id <= 0;
            curr_pkt_fmt <= FMT_LONG_READ;
        end else begin
            state <= next_state;
            curr_pkt_length <= next_curr_pkt_length;
            curr_pkt_id <= next_curr_pkt_id;
            curr_pkt_fmt <= next_curr_pkt_fmt;
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
                if (!tx_cache_if.request_stall) begin
                    next_state = SEND_PKT;
                end
            end
            SEND_PKT : begin
                if (length_done && curr_pkt_fmt == FMT_SWITCH_CFG) begin
                    next_state = IDLE;
                end
                else if(length_done && curr_pkt_fmt != FMT_SWITCH_CFG) begin
                    next_state = CRC;
                end
            end
            CRC : begin
                next_state = IDLE;
            end
            default : begin end
        endcase
    end

    // State output logic
    always_comb begin
        long_hdr = long_hdr_t'(32'd0);
        next_curr_pkt_fmt = curr_pkt_fmt;

        tx_cache_if.addr = tx_if.pkt_start_addr[curr_pkt_id] + (length * 4);
        tx_cache_if.ren = 0;
        tx_cache_if.wen = 0;
        tx_cache_if.strobe = '0;
        tx_cache_if.is_burst = '0;
        tx_cache_if.burst_type = '0;
        tx_cache_if.burst_length = 0;
        tx_cache_if.secure_transfer = 0;
        
        next_curr_pkt_length = curr_pkt_length;
        endpoint_if.data_ready_in = 0;
        flit = flit_t'(0);
        length_clear = 0;
        crc_update = 0;
        crc_in = '0;

        casez (state)
            IDLE : begin
                next_curr_pkt_length = '1;
                length_clear = 1;
            end
            START_SEND_PKT : begin
                tx_cache_if.ren = 1;
                if (!tx_cache_if.request_stall) begin
                    next_curr_pkt_length = expected_num_flits(tx_cache_if.rdata);
                    long_hdr = long_hdr_t'(tx_cache_if.rdata);
                    next_curr_pkt_fmt = long_hdr.format;
                    if(next_curr_pkt_fmt != FMT_SWITCH_CFG) begin
                        next_curr_pkt_length = next_curr_pkt_length - 1;
                    end
                end
            end
            SEND_PKT : begin
                endpoint_if.data_ready_in = !stop_sending && !length_done && crc_done;
                tx_cache_if.ren = 1;
                flit.metadata.vc = 0;
                flit.metadata.id = curr_pkt_id;
                flit.metadata.req = tx_if.node_id;
                flit.payload = tx_cache_if.rdata;
                crc_in = tx_cache_if.rdata;
                crc_update = !crc_done && !length_done && !stop_sending;
            end
            CRC : begin
                flit.metadata.vc = 0;
                flit.metadata.id = curr_pkt_id;
                flit.metadata.req = tx_if.node_id;
                flit.payload = crc_out;
                endpoint_if.data_ready_in = 1;
            end
            default : begin end
        endcase

        endpoint_if.in = flit;
    end
endmodule
