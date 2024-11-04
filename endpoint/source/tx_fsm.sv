`include "chiplet_types_pkg.vh"
`include "phy_manager_if.vh"
`include "tx_fsm_if.sv"

module tx_fsm#(
    parameter NUM_MSGS=4,
    parameter TX_SEND_ADDR=32'h1004
)(
    input logic clk, n_rst,
    tx_fsm_if.tx_fsm tx_if,
    phy_manager_if.rx_switch switch_if,
    bus_protocol_if.protocol tx_cache_if,
    message_table_if.endpoint msg_if
);
    import chiplet_types_pkg::*;

    localparam PKT_MAX_LENGTH = 130;
    localparam LENGTH_WIDTH = $clog2(PKT_MAX_LENGTH);

    typedef enum logic [3:0] {
        IDLE, START_SEND_PKT, SEND_PKT
    } state_e;

    typedef logic [LENGTH_WIDTH-1:0] length_counter_t;

    state_e state, next_state;
    length_counter_t curr_pkt_length, next_curr_pkt_length, length, next_length;
    logic length_clear, length_done;
    logic flit_sent;
    flit_t flit;
    pkt_id_t curr_pkt_id, next_curr_pkt_id;
    long_hdr_t       long_hdr;
    short_hdr_t      short_hdr;
    msg_hdr_t        msg_hdr;
    resp_hdr_t       resp_hdr;
    switch_cfg_hdr_t switch_cfg_hdr;

    socetlib_counter #(.NBITS(LENGTH_WIDTH)) length_counter (
        .CLK(clk),
        .nRST(n_rst),
        .clear(length_clear),
        .count_enable(flit_sent),
        .overflow_val(curr_pkt_length),
        .count_out(length),
        .overflow_flag(length_done)
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

    assign flit_sent = !switch_if.buffer_full && switch_if.data_ready;

    // Next state logic
    always_comb begin
        casez (state)
            IDLE : begin
                if (|msg_if.trigger_send) begin
                    next_state = START_SEND_PKT;
                end
            end
            START_SEND_PKT : begin
                next_state = SEND_PKT;
            end
            SEND_PKT : begin
                if (length_done && flit_sent) begin
                    next_state = IDLE;
                end
            end
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
        long_hdr = long_hdr_t'(tx_bus_if.rdata);
        short_hdr = short_hdr_t'(tx_bus_if.rdata);
        msg_hdr = msg_hdr_t'(tx_bus_if.rdata);
        resp_hdr = resp_hdr_t'(tx_bus_if.rdata);
        switch_cfg_hdr = switch_cfg_hdr_t'(tx_bus_if.rdata);
        next_curr_pkt_length = curr_pkt_length;
        switch_if.data_ready = 0;
        flit = flit_t'(0);

        casez (state)
            IDLE : begin end
            START_SEND_PKT : begin
                case (long_hdr.format)
                    FMT_LONG_READ : begin
                        next_curr_pkt_length = 3; // header + address + crc
                    end
                    FMT_LONG_WRITE : begin
                        next_curr_pkt_length = 3 + // header + address + crc
                            (long_hdr.length ? long_hdr.length : 128); // data
                    end
                    FMT_MEM_RESP : begin
                        next_curr_pkt_length = 2 + // header + crc
                            (resp_hdr.length ? resp_hdr.length : 128); // data
                    end
                    FMT_MSG : begin
                        next_curr_pkt_length = 2 + // header + crc
                            (msg_hdr.length ? msg_hdr.length : 128); // data
                    end
                    FMT_SWITCH_CFG : begin
                        next_curr_pkt_length = 1;
                    end
                    FMT_SHORT_READ : begin
                        next_curr_pkt_length = 2; // header + crc
                    end
                    FMT_SHORT_WRITE : begin
                        next_curr_pkt_length = 2 + // header + crc
                            (short_hdr.length ? short_hdr.length : 16); // data
                    end
                endcase
            end
            SEND_PKT : begin
                switch_if.data_ready = 1;
                tx_cache_if.ren = 1;
                // TODO: how to tell that switch consumed value?
                flit.vc = 0;
                flit.id = curr_pkt_id;
                flit.req = tx_if.node_id;
                flit.payload = tx_bus_if.rdata;
            end
        endcase

        switch_if.flit = flit;
    end
endmodule
