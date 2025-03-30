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
    typedef enum logic [3:0] {SENDING_COMMA, SENDING_DATA, STALL_DATA_SEND, SENDING_START, SENDING_END,IDLE,SEND_GRT_CREDIT,BAUD_1,BAUD_2, ACK_BAUD, CHECK_BAUD_RX} arb_state_t;
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

    arb_counter_if nack_baud_if();
    arb_counter nack_baud(
        .CLK(CLK),
        .nRST(nRST),
        .cnt_if(nack_baud_if)
    )
    assign nack_baud_if.en = arb_if.nack_baud_write;
    assign nack_baud_If.clear = '0;
    assign arb_if.nack_baud_full = nack_baud_if.overflow;


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
    
    // GRT_CTRL_COMMA arbitration queue and counter
    arb_counter_if grt_ctrl_comma_if();
    arb_que_if grt_ctrl_comma_que_if();
    arb_que grt_ctrl_comma_que (
        .CLK(CLK),
        .nRST(nRST),
        .que_if(grt_ctrl_comma_que_if)
    );
    arb_counter grt_ctrl_comma_cnt (
        .CLK(CLK),
        .nRST(nRST),
        .cnt_if(grt_ctrl_comma_if)
    );
    assign grt_ctrl_comma_if.en = arb_if.grt_ctrl_comma_write;
    assign grt_ctrl_comma_if.clear = '0;
    assign arb_if.grt_ctrl_comma_full = grt_ctrl_comma_if.overflow;
    
    assign grt_ctrl_comma_que_if.en = arb_if.grt_ctrl_comma_write;
    assign grt_ctrl_comma_que_if.clear= '0;
    assign grt_ctrl_comma_que_if.count_in = grt_ctrl_comma_if.count;
    assign grt_ctrl_comma_que_if.que_in = arb_if.rx_header;

    // REQ_CTRL_COMMA arbitration queue and counter
    arb_counter_if req_ctrl_comma_if();
    arb_que_if req_ctrl_comma_que_if();
    arb_que req_ctrl_comma_que (
        .CLK(CLK),
        .nRST(nRST),
        .que_if(req_ctrl_comma_que_if)
    );
    arb_counter req_ctrl_comma_cnt (
        .CLK(CLK),
        .nRST(nRST),
        .cnt_if(req_ctrl_comma_if)
    );
    assign req_ctrl_comma_if.en = arb_if.req_ctrl_comma_write;
    assign req_ctrl_comma_if.clear = '0;
    assign arb_if.req_ctrl_comma_full = req_ctrl_comma_if.overflow;
    
    assign req_ctrl_comma_que_if.en = arb_if.req_ctrl_comma_write;
    assign req_ctrl_comma_que_if.clear= '0;
    assign req_ctrl_comma_que_if.count_in = req_ctrl_comma_if.count;
    assign req_ctrl_comma_que_if.que_in = arb_if.rx_header;

    // BAUD_COMMA arbitration queue and counter
    arb_counter_if baud_comma_if();
    arb_que_if baud_comma_que_if();
    arb_que baud_comma_que (
        .CLK(CLK),
        .nRST(nRST),
        .que_if(baud_comma_que_if)
    );
    arb_counter baud_comma_cnt (
        .CLK(CLK),
        .nRST(nRST),
        .cnt_if(baud_comma_if)
    );
    assign baud_comma_if.en = arb_if.baud_comma_write;
    assign baud_comma_if.clear = '0;
    assign arb_if.baud_comma_full = baud_comma_if.overflow;
    
    assign baud_comma_que_if.en = arb_if.baud_comma_write;
    assign baud_comma_que_if.clear= '0;
    assign baud_comma_que_if.count_in = baud_comma_if.count;
    assign baud_comma_que_if.que_in = arb_if.rx_header;

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
                if (baud_req_cred_if.count != 0) begin
                    n_state = SEND_GRT_CREDIT;
                end
                else if (ack_baud_if.count != '0) begin
                    n_state = ACK_BAUD;
                end
                else if (send_data_arb && (grtcred_0_if.count != 0 || grtcred_1_if.count != 0 || ack_if.count != 'd0 || nack_baud_if.count != '0)) begin
                    n_state = SENDING_COMMA;
                end
                else if (~send_data_arb && send_data)begin
                    n_state = SENDING_START;
                end
            end
            SENDING_END, SENDING_COMMA: begin
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
                if (curr_flits_sent == packet_size) begin
                    n_state = SENDING_END;
                end
                else if (arb_if.send_new_data) begin
                    n_state = SENDING_DATA;
                end
            end
            SEND_GRT_CREDIT: begin
                if(ack_baud_if.count != '0) begin
                    n_state = CHECK_BAUD_RX;
                end
                else if (baud_1_if.count < 2) begin
                    n_state = BAUD_1;
                end
                else if (nack_baud_if.count != '0) begin
                    n_state = SENDING_START;
                end
            end
            BAUD_1: begin
                if (arb_if.done) begin
                    n_state = BAUD_2:
                end
            end
            BAUD_2: begin
                if (arb_if.done) begin
                    n_state = IDLE;
                end 
            end
            ACK_BAUD: begin
                if (ack_baud_if.count != '0) begin
                    n_state = CHECK_BAUD_RX;
                end
            end
            CHECK_BAUD_RX: begin
                if (baud_comma_if.count != '0) begin
                    n_state = IDLE;
                end
            end 
            default: begin end
        endcase
    end

    always_comb begin
        arb_if.comma_sel = NADA_SEL;
        arb_if.get_data = '0;
        arb_if.start = '0;
        arb_if.comma_header_out = '0;
        arb_if.set_baud = '0;

        send_data_n = send_data;
        send_data_arb_n = send_data_arb;
        n_size_of_packet = packet_size;

        // Default queue and counter decrements
        grtcred_0_if.dec = '0;
        grtcred_1_if.dec = '0;
        ack_if.dec = '0;
        ack_que_if.dec = '0;
        nack_baud_if.dec = '0;
        baud_comma_if.dec = '0;
        baud_comma_que_if.dec = '0;
        req_ctrl_comma_if.dec = '0;
        req_ctrl_comma_que_if.dec = '0;
        grt_ctrl_comma_if.dec = '0;
        grt_ctrl_comma_que_if.dec = '0;

        flit_cnt_en = '0;
        clear_cnt = '0;
        case (state)
            IDLE: begin
                send_data_n = send_data ? send_data : arb_if.data_write;
                if (baud_req_cred_if.count != 0) begin
                    arb_if.start = '1;
                    baud_req_cred_que_if.dec = '1;
                    arb_if.comma_header_out = baud_req_cred_que_if.que_out;
                    arb_if.comma_sel = REQ_CTRL_BAUD_SEL;
                end
                else if (ack_baud_if.count != '0) begin
                    arb_if.start = '1;
                    ack_baud_if.dec = '1;
                    arb_if.comma_header_out = ack_baud_que_if.que_out;
                    arb_if.comma_sel = GRT_CTRL_BAUD_SEL;
                end
                else if (send_data_arb) begin
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
                    else if (nack_baud_if.count != 'd0) begin
                        arb_if.start = '1;
                        arb_if.comma_sel =  NACK_CTRL_BAUD_COMMA;
                    end
                end
                else begin
                    if (send_data != 'd0) begin
                        arb_if.comma_sel = START_PACKET_SEL;
                        arb_if.start = '1;
                    end
                end
                send_data_arb_n = !send_data_arb;
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
                    else if (nack_baud_if.count != 'd0) begin
                        nack_baud_if.dec = '1;
                    end
                end
            end
            STALL_DATA_SEND: begin
                if (curr_flits_sent != packet_size && arb_if.send_new_data) begin
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
            SEND_GRT_CREDIT: begin
                if(ack_baud_if.count != '0) begin
                    arb_if.start = '1;
                    arb_if.comma_sel = GRT_CTRL_BAUD_SEL;
                    arb_if.comma_header_out = grt_ctr_baud_que_if.que_out;
                    arb_if.get_data = '1;
                end
                else if (baud_comma_if.count < 2) begin
                    arb_if.start = '1;
                    arb_if.comma_sel = BAUD_SEL;
                    arb_if.comma_header_out = baud_comma_que_if.que_out;
                    baud_comma_que_if.dec = '1;
                    baud_comma_if.dec = '1;
                end
                else if (nack_baud_if.count != '0) begin
                    arb_if.start = '1;
                    arb_if.comma_sel = START_PACKET_SEL;
                end
            end
            SEND_BAUD_1: begin
                if (arb_if.done) begin
                    arb_if.start = '1;
                    arb_if.comma_sel = BAUD_SEL;
                    arb_if.comma_header_out = baud_comma_que_if.que_out;
                    baud_comma_que_if.dec = '1;
                    baud_comma_if.dec = '1;
                end
            end
            SEND_BAUD_2: begin
                if (ack_baud_if.count != '0) begin
                    arb_if.start = '1;
                    ack_baud_que_if.dec = '1;
                    arb_if.comma_header_out = ack_baud_que_if.que_out;
                    arb_if.comma_sel = GRT_CTRL_BAUD_SEL;
                    ack_baud_if.dec = '1;
                    arb_if.set_baud ='1;
                end
            end
            ACK_BAUD: begin
                if (ack_baud_if.count != '0) begin
                    arb_if.start = '1;
                    baud_req_cred_que_if.dec = '1;
                    arb_if.comma_header_out = baud_req_cred_que_if.que_out;
                    arb_if.comma_sel = REQ_CTRL_BAUD_SEL;
                    arb_if.set_baud = '1;
                end
            end
            CHECK_BAUD_RX: begin
                if (baud_comma_if.count != '0) begin
                    baud_comma_if.dec = '1;
                end
            end 
            default: begin end
        endcase
    end
endmodule
