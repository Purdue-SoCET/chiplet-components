/*

* notes on uart:
    when transmiting send data at same time as start bit
*   comma sel determines the size use defined parameters in module to determine select comma value

*

*/
module uart_tx #(parameter PORTCOUNT = 5,parameter CLKDIV_W = 4, parameter [(CLKDIV_W - 1):0]  CLKDIV_COUNT = 'd10)
                (input logic CLK, nRST, start,
                 input logic [1:0] comma_sel,
                 input logic [(PORTCOUNT * 10 -1):0] data,
                 output logic done, tx_err,
                 output logic [(PORTCOUNT -1):0] uart_out);


parameter [1:0]SELECT_COMMA_1_FLIT = 2'b1;
parameter [1:0]SELECT_COMMA_2_FLIT = 2'd2;
parameter [1:0]SELECT_COMMA_DATA   = 2'd3;
//shift reg
logic shift_en;
logic [(PORTCOUNT - 1):0]shift_reg_out;
logic [1:0]comma_sel_reg, n_comma_sel_reg;
genvar i;
generate for (i = 0; i < PORTCOUNT;i = i +1) begin : shift_reg_block
socetlib_shift_reg #(
    .NUM_BITS(10),
	.SHIFT_MSB(1)  
) sr
(   .clk(CLK),
	.nRST(nRST),
	.shift_enable(shift_en),
    .parallel_load(start),
    .serial_in('1),
	.parallel_in({data[9 * PORTCOUNT + i],data[8 * PORTCOUNT + i],data[7 * PORTCOUNT + i],data[6 * PORTCOUNT + i],data[5 * PORTCOUNT + i],
                  data[4 * PORTCOUNT + i],data[3 * PORTCOUNT + i],data[2 * PORTCOUNT + i],data[PORTCOUNT  + i],data[i]}),
	.serial_out(shift_reg_out[i])
);
end
endgenerate
logic clk_flag,clk_en;
socetlib_counter #(.NBITS(CLKDIV_W)) clk_count
(
    .CLK(CLK),
    .nRST(nRST),
    .clear(tx_err),
    .overflow_val((CLKDIV_COUNT)),
    .count_enable(clk_en),
    .overflow_flag(clk_flag)
);
//clk div
//bit sent counter

logic [3:0] length_of_message;

socetlib_counter #(.NBITS(4))  bit_count
(
    .CLK(CLK),
    .nRST(nRST),
    .clear(tx_err || done),
    .count_enable(clk_flag),

    .overflow_val(length_of_message),
    .overflow_flag(byte_flag)
);

always_comb begin
    length_of_message = '0;
    case (comma_sel_reg) 
    SELECT_COMMA_1_FLIT :begin
            length_of_message = 4'd3;
        end
    SELECT_COMMA_2_FLIT :begin
            length_of_message = 4'd5;
        end
    SELECT_COMMA_DATA   :begin
            length_of_message = 4'd11;

        end
    endcase
end

//Control Unit

typedef enum logic[2:0] {IDLE,START,SENDING,DONE,ERROR}uart_state;
uart_state state, n_state;
always_ff @(posedge CLK, negedge nRST) begin
    if ( ~nRST) begin
        state <= IDLE;
        comma_sel_reg <= '0;
    end
    else begin
        state <= n_state;
        comma_sel_reg <= n_comma_sel_reg;
    end
end

always_comb begin
    n_state = state;
    shift_en = 1'b0;
    done = 1'b0;
    uart_out = '1;
    n_comma_sel_reg = comma_sel_reg;
    clk_en = '0;
    tx_err = '0;
    case (state)
    IDLE: begin
        uart_out = '1;
        if (start) begin
            n_state = START;
            n_comma_sel_reg = comma_sel;
        end
    end
    START:begin
        clk_en = 1'b1;
        uart_out = '0;
        if(start) begin
            n_state = ERROR;
        end
        else if (clk_flag) begin
            n_state = SENDING;
        end
    end
    SENDING: begin
        uart_out = shift_reg_out;
        clk_en = 1'b1;
        shift_en = 1'b0;
        
        if (clk_flag) begin
            shift_en = 1'b1;
        end
        
        if (start) begin
            n_state = ERROR;
        end
        else if (byte_flag) begin
            shift_en = 1'b1;
            n_state = DONE;
        end 
    end
    DONE: begin
        clk_en = 1'b1;
        shift_en = 'b0;
        uart_out = '1;
        if ( clk_flag) begin
            done = '1;
            n_state = IDLE; 
        end
        else if (start) begin
            n_state = ERROR;
        end 
    end
    ERROR:begin
        tx_err = '1;
        if (start) begin
            n_state = START;
        end
    end
    endcase

end

endmodule
