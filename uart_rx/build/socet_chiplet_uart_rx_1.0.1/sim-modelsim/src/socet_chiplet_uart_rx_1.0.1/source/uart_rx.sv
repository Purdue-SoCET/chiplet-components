`timescale 1ns / 10ps


module uart_rx # (parameter PORTCOUNT =5, parameter CLKDIV_W = 10,  parameter [(CLKDIV_W - 1):0]  CLKDIV_COUNT = 'd10)
                 (input logic CLK, nRST,
                  input logic [(PORTCOUNT -1):0] uart_in,
                  output logic [(PORTCOUNT * 10 -1):0] data,
                  output logic [1:0] comma_sel,
                  output logic done, rx_err);

parameter [1:0]SELECT_COMMA_1_FLIT = 2'b1;
parameter [1:0]SELECT_COMMA_2_FLIT = 2'b10;
parameter[1:0] SELECT_COMMA_DATA   = 2'b11;
logic message_done, start,clk_en,sent_flag,shift_en; 
logic [(PORTCOUNT - 1):0] sync_out;
logic [3:0]bit_sent_count;
logic [3:0] length_of_message;
typedef enum logic [3:0]{IDLE, RECIEVE, ERROR,DONE, START} rx_states;
rx_states state , n_state;
assign message_done = & sync_out;
assign start = ~(|sync_out);
genvar i;
generate for (i = 0; i < PORTCOUNT;i = i +1) begin : sync_block
socetlib_synchronizer   sync
         (.CLK(CLK),
          .nRST(nRST),
          .async_in(uart_in[i]),
          .sync_out(sync_out[i])
        );
end
endgenerate

generate for (i = 0; i < PORTCOUNT;i = i +1) begin : shift_reg
socetlib_shift_reg shift_reg
(   .clk(CLK),
	.nRST(nRST),
	.shift_enable(shift_en),
	.serial_in(sync_out[i]),
    .parallel_load(),
	.parallel_out({data[9 * PORTCOUNT + i],data[8 * PORTCOUNT + i],data[7 * PORTCOUNT + i],data[6 * PORTCOUNT + i],data[5 * PORTCOUNT + i],
                  data[4 * PORTCOUNT + i],data[3 * PORTCOUNT + i],data[2 * PORTCOUNT + i],data[PORTCOUNT  + i],data[i]})
);
end
endgenerate

socetlib_counter_rx_timer #(.NBITS(CLKDIV_W),.COUNT_TO(CLKDIV_COUNT))
 clk_count
(
    .CLK(CLK),
    .nRST(nRST),
    .clear(rx_err),
    .count_enable(clk_en),
    .overflow_flag(clk_flag)
);
//clk div
//bit sent counter



socetlib_counter  #(.NBITS(4)) bit_count
(
    .CLK(CLK),
    .nRST(nRST),
    .clear(rx_err || state == IDLE),
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
    comma_sel = '0;
    clk_en = '0;
    shift_en ='0;
    done = '0;
    case(state)
        IDLE:
        begin
            if (start) begin
                n_state = START;
            end
        end
        START:
        begin
            clk_en = '1;
            if (clk_flag ) begin
                n_state =RECIEVE;
            end
           else if (message_done || start != '1) begin
                n_state = ERROR;
            end
        end
        RECIEVE: begin
            clk_en = 1'b1;
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
            else if (clk_flag) begin
                shift_en = 1'b1;
            end
            

            
        end
        DONE:
        begin
            done = '1;
            clk_en = '1;
            case(bit_sent_count)
            4'd3: comma_sel = SELECT_COMMA_1_FLIT;
            4'd5: comma_sel = SELECT_COMMA_2_FLIT;
            4'd11: comma_sel = SELECT_COMMA_1_FLIT;
            default: n_state = ERROR;
            endcase
                n_state = IDLE;
        end
        
        ERROR: begin
            rx_err = 1'b1;
            if(start) begin
                n_state = START;
            end
        end

    endcase

end
endmodule
