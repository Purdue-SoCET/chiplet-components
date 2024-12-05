`timescale 1ns / 10ps
`include "uart_rx_if.sv"
`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
module uart_rx # (parameter PORTCOUNT =5, parameter CLKDIV_COUNT = 10)
                 (input logic CLK, nRST,
                  uart_rx_if.rx rx_if);

import phy_types_pkg::*;
logic message_done, start,clk_en,sent_flag,shift_en, clk_flag;
logic [(PORTCOUNT - 1):0] sync_out;
logic [3:0]bit_sent_count;
logic [3:0] length_of_message;
typedef enum logic [3:0]{IDLE, RECIEVE, ERROR,DONE, START} rx_states;
rx_states state , n_state;
assign message_done = &sync_out;
assign start = ~(|sync_out);
genvar i;
generate for (i = 0; i < PORTCOUNT;i = i +1) begin : sync_block
socetlib_synchronizer   sync
         (.CLK(CLK),
          .nRST(nRST),
          .async_in(rx_if.uart_in[i]),
          .sync_out(sync_out[i])
        );
end
endgenerate

generate for (i = 0; i < PORTCOUNT;i = i +1) begin : shift_reg
    socetlib_shift_reg #(
        .NUM_BITS(10)
    ) shift_reg (
        .clk(CLK),
        .nRST(nRST),
        .shift_enable(shift_en),
        .serial_in(sync_out[i]),
        .parallel_load(0),
        .parallel_in('1),
        .serial_out(),
        .parallel_out({rx_if.data[9 * PORTCOUNT + i],rx_if.data[8 * PORTCOUNT + i],rx_if.data[7 * PORTCOUNT + i],rx_if.data[6 * PORTCOUNT + i],rx_if.data[5 * PORTCOUNT + i],
                      rx_if.data[4 * PORTCOUNT + i],rx_if.data[3 * PORTCOUNT + i],rx_if.data[2 * PORTCOUNT + i],rx_if.data[PORTCOUNT  + i],rx_if.data[i]})
);
end
endgenerate

rx_timer #(.NBITS($clog2(CLKDIV_COUNT)),.COUNT_TO(CLKDIV_COUNT))
 clk_count
(
    .CLK(CLK),
    .nRST(nRST),
    .clear(rx_if.rx_err),
    .count_enable(clk_en),
    .overflow_flag(clk_flag)
);
//clk div
//bit sent counter



socetlib_counter  #(.NBITS(4)) bit_count
(
    .CLK(CLK),
    .nRST(nRST),
    .clear(rx_if.rx_err || state == IDLE),
    .count_enable(clk_flag && state == RECIEVE),
    .overflow_val(4'd11),
    .count_out(bit_sent_count),
    .overflow_flag(sent_flag)
);

//fsm

always_ff @(posedge CLK, negedge nRST) begin
    if(~nRST) begin
        state <= IDLE;
    end
    else begin
        state <= n_state;
    end
end

always_comb begin
    n_state = state;
    case(state)
        IDLE:
        begin
            if (start) begin
                n_state = START;
            end
        end
        START:
        begin
            if (clk_flag ) begin
                n_state =RECIEVE;
            end
           else if (message_done || start != '1) begin
                n_state = ERROR;
            end
        end
        RECIEVE: begin
            if (clk_flag &&start) begin
                n_state = ERROR;
            end
            else if(message_done && clk_flag) begin
                if(bit_sent_count == 4'd2 || bit_sent_count == 4'd4 || bit_sent_count == 4'd10) begin
                    n_state = DONE;
                end
                else begin
                    n_state = ERROR;
                end
            end
        end
        DONE:
        begin
            if (bit_sent_count != 'd3 || bit_sent_count != 'd5 || bit_sent_count != 'd11)
            n_state = IDLE;
        end
        ERROR: begin
            if(start) begin
                n_state = START;
            end
        end
        default begin
        end
    endcase

end



always_comb begin
    rx_if.comma_sel = NADA;
    clk_en = '0;
    shift_en ='0;
    rx_if.done = '0;
    rx_if.rx_err = '0;
    case(state)
        START:
        begin
            clk_en = '1;
        end
        RECIEVE: begin
            clk_en = 1'b1;
            if (clk_flag && ~message_done && ~start) begin
                shift_en = 1'b1;
            end
        end
        DONE:
        begin
            rx_if.done = '1;
            clk_en = '1;
            case(bit_sent_count)
            4'd3: rx_if.comma_sel = SELECT_COMMA_1_FLIT;
            4'd5: rx_if.comma_sel = SELECT_COMMA_2_FLIT;
            4'd11: rx_if.comma_sel = SELECT_COMMA_DATA;
            default: begin
            end
            endcase
        end
        ERROR: begin
            rx_if.rx_err = 1'b1;
        end
        default: begin 
            rx_if.comma_sel = NADA;
            clk_en = '0;
            shift_en ='0;
            rx_if.done = '0;
            rx_if.rx_err = '0;
        end
    endcase

end
endmodule
