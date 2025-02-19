`timescale 1ns / 10ps

module arbitration_buffer #(parameter COUNTER_SIZE = 4) (input logic CLK, nRST, arbitration_buffer_if.arb arb_if);
//needed FSM to select to tx
//incrementing and decrement ing
import phy_types_pkg::*;
import chiplet_types_pkg::*; 
typedef enum logic [2:0] {SENDING_COMMA, SENDING_DATA, SENDING_START,SENDING_END,IDLE} arb_state_t;
arb_state_t state, n_state;

// TODO: find a way to do this in a for loop 
arb_counter_if ack_if();
arb_que_if ack_que_if();
arb_que ack_que(.CLK(CLK),.nRST(nRST),.que_if(ack_que_if));
arb_counter  ack_counter (.CLK(CLK),.nRST(nRST),.cnt_if(ack_if));
assign ack_if.en = arb_if.ack_write;
assign ack_if.clear = '0;
assign arb_if.ack_cnt_full = ack_if.overflow;

assign ack_que_if.en = arb_if.ack_write;
assign ack_que_if.clear= '0;
assign ack_que_if.count_in = ack_if.count;
assign ack_que_if.que_in = arb_if.rx_header;

arb_counter_if nack_if();
arb_que_if nack_que_if();
arb_que nack_que(.CLK(CLK),.nRST(nRST),.que_if(nack_que_if));
arb_counter nack_counter (.CLK(CLK),.nRST(nRST),.cnt_if(nack_if));
assign nack_if.en = arb_if.nack_write;
assign nack_if.clear = '0;
assign arb_if.nack_cnt_full = nack_if.overflow;

assign nack_que_if.en = arb_if.nack_write;
assign nack_que_if.clear= '0;
assign nack_que_if.count_in = nack_if.count;
assign nack_que_if.que_in = arb_if.rx_header;
arb_counter_if res0_if();
arb_que_if res0_que_if();
arb_que res0_que(.CLK(CLK),.nRST(nRST),.que_if(res0_que_if));
arb_counter res0_counter (.CLK(CLK),.nRST(nRST),.cnt_if(res0_if));
assign res0_if.en = arb_if.rs0_write;
assign res0_if.clear = '0;
assign arb_if.rs0_cnt_full =res0_if.overflow;

assign res0_que_if.en = arb_if.rs0_write;
assign res0_que_if.clear= '0;
assign res0_que_if.count_in = res0_if.count;
assign res0_que_if.que_in = arb_if.rx_header;

arb_counter_if res1_if();
arb_que_if res1_que_if();
arb_que res1_que(.CLK(CLK),.nRST(nRST),.que_if(res1_que_if));
arb_counter res1_counter (.CLK(CLK),.nRST(nRST),.cnt_if(res1_if));
assign res1_if.en = arb_if.rs1_write;
assign res1_if.clear = '0;
assign arb_if.rs1_cnt_full =res1_if.overflow;


assign res1_que_if.en = arb_if.rs1_write;
assign res1_que_if.clear= '0;
assign res1_que_if.count_in = res1_if.count;
assign res1_que_if.que_in = arb_if.rx_header;

arb_counter_if res2_if();
arb_que_if res2_que_if();
arb_que res2_que(.CLK(CLK),.nRST(nRST),.que_if(res2_que_if));
arb_counter res2_counter (.CLK(CLK),.nRST(nRST),.cnt_if(res2_if));
assign res2_if.en = arb_if.rs2_write;
assign res2_if.clear = '0;
assign arb_if.rs2_cnt_full =res2_if.overflow;

assign res2_que_if.en = arb_if.rs2_write;
assign res2_que_if.clear= '0;
assign res2_que_if.count_in = res2_if.count;
assign res2_que_if.que_in = arb_if.rx_header;

arb_counter_if res3_if();
arb_que_if res3_que_if();
arb_que res3_que(.CLK(CLK),.nRST(nRST),.que_if(res3_que_if));
arb_counter res3_counter (.CLK(CLK),.nRST(nRST),.cnt_if(res3_if));
assign res3_if.en = arb_if.rs3_write;
assign res3_if.clear = '0;
assign arb_if.rs3_cnt_full =res3_if.overflow;

assign res3_que_if.en = arb_if.rs2_write;
assign res3_que_if.clear= '0;
assign res3_que_if.count_in = res3_if.count;
assign res3_que_if.que_in = arb_if.rx_header;

arb_counter_if send_data_if();
arb_counter data_counter (.CLK(CLK),.nRST(nRST),.cnt_if(send_data_if));
assign send_data_if.en = arb_if.data_write;
assign send_data_if.clear = '0;
assign arb_if.send_data_cnt_full = send_data_if.overflow;

logic send_data_arb,send_data_arb_n;
always_ff @(posedge CLK, negedge nRST) begin
    if (!nRST) begin
        state <= IDLE;
        send_data_arb <= 'b0;
    end
    else begin
        state <= n_state;
        send_data_arb <= send_data_arb_n;
    end
end

always_comb begin
    n_state = state;
    case (state)
    IDLE: begin
        if (send_data_arb && (nack_if.count != 'd0 || ack_if.count != 'd0 
            || res0_if.count != 'd0 || res1_if.count != 'd0 || res2_if.count != 'd0
            || res3_if.count != 'd0)) begin
            n_state = SENDING_COMMA;
        end
        else if (~send_data_arb && send_data_if.count != 'd0 )begin
            n_state = SENDING_START;
        end
    end
    SENDING_END,
    SENDING_COMMA: begin
        if(arb_if.done) begin
            n_state = IDLE;
        end
    end
    SENDING_START: begin
        if(arb_if.done) begin
            n_state = SENDING_DATA;
        end
    end

    SENDING_DATA: begin
        if(arb_if.done) begin
            n_state = SENDING_END;
        end
    end
    default:begin

    end
    endcase
end

always_comb begin
    arb_if.comma_sel = START_PACKET_SEL;
    arb_if.get_data = '0;
    res0_if.dec = '0;
    res1_if.dec = '0;
    res2_if.dec = '0;
    res3_if.dec = '0;
    nack_if.dec ='0;
    ack_if.dec ='0;
    arb_if.start = '0;
    send_data_if.dec = '0;
    arb_if.comma_header_out = '0;
    case (state)
    IDLE: begin
        if (send_data_arb)begin 
            if (nack_if.count != 'd0) begin
                arb_if.comma_sel = NACK_SEL;
                nack_if.dec = '1;
                arb_if.start = '1;
                nack_que_if.dec = '1;
                arb_if.comma_header_out = nack_que_if.que_out;
            end
            else if (ack_if.count != 'd0) begin
                arb_if.comma_sel = ACK_SEL;
                ack_if.dec = '1;
                arb_if.start = '1;
                ack_que_if.dec = '1;
                arb_if.comma_header_out = ack_que_if.que_out;
            end
            else if ( res0_if.count != 'd0) begin
                arb_if.comma_sel = RESEND_PACKET0_SEL;
                res0_if.dec = '1;
                arb_if.start = '1;
                res0_que_if.dec = '1;
                arb_if.comma_header_out = res0_que_if.que_out;
            end
            else if ( res1_if.count != 'd0) begin
                arb_if.comma_sel = RESEND_PACKET1_SEL;
                res1_if.dec = '1;
                arb_if.start = '1;
                res1_que_if.dec = '1;
                arb_if.comma_header_out = res1_que_if.que_out;
            end
            else if ( res2_if.count != 'd0) begin
                arb_if.comma_sel = RESEND_PACKET2_SEL;
                res2_if.dec = '1;
                arb_if.start = '1;
                res2_que_if.dec = '1;
                arb_if.comma_header_out = res2_que_if.que_out;
            end
            else if ( res3_if.count != 'd0) begin
                arb_if.comma_sel = RESEND_PACKET3_SEL;
                res3_if.dec = '1;
                arb_if.start = '1;
                res3_que_if.dec = '1;
                arb_if.comma_header_out = res3_que_if.que_out;
            end
        end
        else begin
            if (send_data_if.count != 'd0) begin
                arb_if.comma_sel = START_PACKET_SEL;
                send_data_if.dec = '1;
                arb_if.start = '1;
            end
        end
        send_data_arb_n = ~send_data_arb;
    end
    SENDING_START: begin
        if(arb_if.done) begin
            arb_if.get_data = '1;
            arb_if.comma_sel = DATA_SEL;
            arb_if.start = '1;
        end
    end 
    SENDING_DATA: begin
         if (arb_if.packet_done) begin
            arb_if.comma_sel = END_PACKET_SEL;
            arb_if.start = '1;
        end
        else if (arb_if.done) begin
            arb_if.start = '1;
            arb_if.get_data = '1;
            arb_if.comma_sel = DATA_SEL;
        end
       
    end
    SENDING_END: begin
    end
    default:begin
    end
    endcase
end



endmodule