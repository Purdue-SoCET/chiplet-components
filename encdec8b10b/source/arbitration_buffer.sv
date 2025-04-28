`timescale 1ns / 10ps

// `include "arbitration_buffer_if.sv"
module arbitration_buffer #(
    parameter COUNTER_SIZE = 4
)(
    input logic CLK, nRST,
    arbitration_buffer_if.arb arb_if
);
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

    //needed FSM to select to tx
    //incrementing and decrement ing
    typedef enum logic [2:0] {SENDING_COMMA, SENDING_DATA, STALL_DATA_SEND, SENDING_START, SENDING_END,IDLE} arb_state_t;
    arb_state_t state, n_state;

    // TODO: find a way to do this in a for loop
    arb_counter_if ack_if();
    arb_que_if ack_que_if();
    arb_que ack_que(
        .CLK(CLK),
        .nRST(nRST),
        .que_if(ack_que_if)
    );
    arb_counter ack_counter(
        .CLK(CLK),
        .nRST(nRST),
        .cnt_if(ack_if)
    );
    assign ack_if.en = arb_if.ack_write;
    assign ack_if.clear = '0;
    assign arb_if.ack_cnt_full = ack_if.overflow;

    assign ack_que_if.en = arb_if.ack_write;
    assign ack_que_if.clear= '0;
    assign ack_que_if.count_in = ack_if.count;
    assign ack_que_if.que_in = arb_if.rx_header;

    arb_counter_if grtcred_0_if();
    arb_counter grtcred0_cnt (
        .CLK(CLK),
        .nRST(nRST),
        .cnt_if(grtcred_0_if)
    );
    assign grtcred_0_if.en = arb_if.grtcred0_write;
    assign grtcred_0_if.clear = '0;
    assign arb_if.grtcred_0_full = grtcred_0_if.overflow;

    arb_counter_if grtcred_1_if();
    arb_counter grtcred1_cnt(
        .CLK(CLK),
        .nRST(nRST),
        .cnt_if(grtcred_1_if)
    );
    assign grtcred_1_if.en = arb_if.grtcred1_write;
    assign grtcred_1_if.clear = '0;
    assign arb_if.grtcred_1_full = grtcred_1_if.overflow;

    logic flit_cnt_flag;
    logic flit_cnt_en;
    logic clear_cnt;
    socetlib_counter #(
        .NBITS(9)
    ) flit_cnt (
        .CLK(CLK),
        .nRST(nRST),
        .clear(clear_cnt),
        .overflow_val(packet_size),
        .count_enable(flit_cnt_en),
        .overflow_flag(flit_cnt_flag),
        .count_out(curr_flits_sent)
    );

    logic send_data, send_data_n;
    logic send_data_arb,send_data_arb_n;
    logic [8:0] packet_size, n_size_of_packet, curr_flits_sent;

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            state <= IDLE;
            send_data_arb <= 'b0;
            send_data <= '0;
            packet_size <= '0;
        end
        else begin
            state <= n_state;
            send_data_arb <= send_data_arb_n;
            send_data <= send_data_n;
            packet_size <= n_size_of_packet;
        end
    end

    always_comb begin
        n_state = state;
        case (state)
            IDLE: begin
                if ((grtcred_0_if.count != 0 || grtcred_1_if.count != 0 || ack_if.count != 'd0)) begin
                    n_state = SENDING_COMMA;
                end
                else if (send_data)begin
                    n_state = SENDING_START;
                end
            end
            SENDING_END, SENDING_COMMA: begin
                if (arb_if.done && send_data) begin
		    n_state = STALL_DATA_SEND;
		end
		if (arb_if.done) begin
                    n_state = IDLE;
                end
            end
            SENDING_START: begin
                if (arb_if.done) begin
                    n_state = STALL_DATA_SEND;
                end
            end
            SENDING_DATA: begin
                if (arb_if.done) begin
                    n_state = STALL_DATA_SEND;
                end
            end
            STALL_DATA_SEND: begin
                if (grtcred_0_if.count != 0 || grtcred_1_if.count != 0) begin
		    n_state = SENDING_COMMA;
                end
                else if (curr_flits_sent == packet_size) begin
                    n_state = SENDING_END;
                end
                else if (arb_if.send_new_data) begin
                    n_state = SENDING_DATA;
                end
            end
            default: begin end
        endcase
    end

    always_comb begin
        arb_if.comma_sel = NADA_SEL;
        arb_if.get_data = '0;
        grtcred_0_if.dec = '0;
        ack_if.dec ='0;
        grtcred_1_if.dec = '0;
        ack_que_if.dec ='0;
        arb_if.start = '0;
        flit_cnt_en = '0;
        clear_cnt ='0;
        n_size_of_packet = packet_size;
        arb_if.comma_header_out = '0;
        send_data_arb_n = send_data_arb;
        send_data_n = send_data;
        case (state)
            IDLE: begin
                send_data_n = send_data ? send_data : arb_if.data_write;
                    if (grtcred_0_if.count != '0) begin
                        arb_if.start = '1;
                        arb_if.comma_sel = GRTCRED0_SEL;
                    end
                    else if (grtcred_1_if.count != '0) begin
                        arb_if.start = '1;
                        arb_if.comma_sel = GRTCRED1_SEL;
                    end
                    else if (ack_if.count != 'd0) begin
                        arb_if.comma_sel = ACK_SEL;
                        arb_if.start = '1;
                        ack_que_if.dec = '1;
                        arb_if.comma_header_out = ack_que_if.que_out;
                    end
                    else if (send_data != 'd0) begin
                        arb_if.comma_sel = START_PACKET_SEL;
                        arb_if.start = '1;
                    end
            end
            SENDING_START: begin
                if (arb_if.done) begin
                    n_size_of_packet = expected_num_flits(arb_if.flit_data);
                end
            end
            SENDING_DATA: begin
                if (arb_if.done) begin
                    arb_if.get_data = '1;
                end
            end
            SENDING_COMMA: begin
                if (arb_if.done) begin
                    if (grtcred_0_if.count != '0) begin
                        grtcred_0_if.dec = '1;
                    end
                    else if (grtcred_1_if.count != '0) begin
                        grtcred_1_if.dec = '1;
                    end
                    else if (ack_if.count != 'd0) begin
                        ack_if.dec = '1;
                    end
                end
            end
            STALL_DATA_SEND: begin
		if (grtcred_0_if.count != '0) begin
		    arb_if.start = '1;
		    arb_if.comma_sel = GRTCRED0_SEL;
		end
		else if (grtcred_1_if.count != '0) begin
		    arb_if.start = '1;
		    arb_if.comma_sel = GRTCRED1_SEL;
		end
                else if (curr_flits_sent != packet_size && arb_if.send_new_data) begin
                    flit_cnt_en = '1;
                    arb_if.start = '1;
                    arb_if.comma_sel = DATA_SEL;
                end
                else if (curr_flits_sent == packet_size) begin
                    arb_if.start = '1;
                    arb_if.comma_sel = END_PACKET_SEL;
                end
            end
            SENDING_END: begin
                send_data_n = '0;
                clear_cnt = '1;
            end
            default: begin end
        endcase
    end
endmodule
