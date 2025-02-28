module fpga_endpoint_uart_fsm(
    input logic clk, n_rst,
    input logic serial_in
    bus_protocol_if.protocol bus_if,
)
    import phy_types_pkg::*;
logic message_done, start,clk_en,sent_flag,shift_en, clk_flag;
logic sync_out;
logic [3:0]bit_sent_count;
typedef enum logic [3:0]{IDLE, RECIEVE, ERROR,DONE, START} rx_states;
rx_states state , n_state;
assign message_done = sync_out;
assign start = !sync_out;

socetlib_synchronizer sync(
    .CLK(clk),
    .nRST(n_rst),
    .async_in(serial_in),
    .sync_out(sync_out)
);

socetlib_shift_reg #(
    .NUM_BITS(10)
) shift_reg (
    .clk(clk),
    .nRST(n_rst),
    .shift_enable(shift_en),
    .serial_in(sync_out[i]),
    .parallel_load(0),
    .parallel_in('1),
    .serial_out(),
    .parallel_out()
);


rx_timer #(.NBITS($clog2(CLKDIV_COUNT)),.COUNT_TO(CLKDIV_COUNT))
 clk_count
(
    .CLK(clk),
    .nRST(n_rst),
    .clear(rx_if.rx_err),
    .count_enable(clk_en),
    .overflow_flag(clk_flag)
);
//clk div
//bit sent counter



socetlib_counter  #(.NBITS(4)) bit_count
(
    .CLK(clk),
    .nRST(n_rst),
    .clear(state == IDLE),
    .count_enable(clk_flag && state == RECIEVE),
    .overflow_val(4'd8),
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
            4'd11: rx_if.comma_sel = SELECT_COMMA_1_FLIT;
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