/*

* notes on uart:
    when transmiting send data at same time as start bit
*   comma sel determines the size use defined parameters in module to determine select comma value

*

*/
module uart_tx #(parameter PORTCOUNT = 5,parameter CLKDIV_W = 10, parameter CLKDIV_COUNT = (CLKDIV_W)'d10); 
                (input logic CLK, nRST, start,
                 input logic [1:0] comma_sel,
                 input logic [(PORTCOUNT * 10 -1):0] data;
                 output logic done, tx_err,
                 output logic [(PORTCOUNT -1):0] uart_out);


parameter SELECT_COMMA_1_FLIT = 2'b1;
parameter SELECT_COMMA_2_FLIT = 2'd2;
parameter SELECT_COMMA_DATA   = 2'd3;
//shift reg
logic [(PORTCOUNT * 10 -1):0] shift_reg, n_shift_reg; 
logic shift_en;
always_ff @(posedge CLK, negedge nRST) begin
    if ( ~nRST) begin
        shift_reg <= 'b0;
    end
    else begin
        shift_reg <= n_shift_reg;
    end
end

always_comb begin
    n_shift_reg = shift_reg;

    if (tx_err) begin
        n_shift_reg ='1;
    end
    else if (start) begin
        if (comma_sel ==SELECT_COMMA_1_FLIT) begin
            n_shift_reg = {(PORTCOUNT * 10 - 1)'1,data[(PORTCOUNT - 1):0]};
        end
        else if (comma_sel == SELECT_COMMA_2_FLIT) begin
            n_shift_reg = {(PORTCOUNT * 10 - 1)'1,data[(PORTCOUNT * 2 - 1):0]};
        end

        else begin
            n_shift_reg = data;
        end
    end
    else if (shift_en)begin
        n_shift_reg = {(PORTCOUNT)'1,shift_reg[(PORTCOUNT * 10 - 1):PORTCOUNT]};
    end
end

//clk div
logic [(CLKDIV_W - 1):0]clk_div_count, n_clk_div_count;
logic clk_flag, n_clk_flag,clk_en;
always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        clk_div_count <= 'b0;
        clk_flag <= 'b0;
    end
    else begin
        clk_div_count <= n_clk_div_count;
        clk_flag <= n_clk_flag;
    end
end

always_comb begin
    n_clk_div_count = clk_div_count;
    n_clk_flag = 'b0;
    if (tx_err || done) begin
        n_clk_div_count = 'b0;
    end
    else if (clk_en) begin
        if (clk_div_count == (CLKDIV_COUNT -1)) begin
            n_clk_flag = 1'b1;
            n_clk_div_count = clk_div_count + 1;
        end
        else if (clk_div_count == (CLKDIV_COUNT)) begin
            n_clk_div_count = 'b1;
        end
        else begin
        n_clk_div_count = clk_div_count + 1;
        end
    end
end

//bit sent counter
logic [(CLKDIV_W - 1):0]bit_sent_count, n_bit_sent_count;
logic clk_flag, n_flit_flag;
logic [4:0] length_of_message;

always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        bit_sent_count <= 'b0;
        flit_flag <= 'b0;
    end
    else if (clk_flag) begin
        bit_sent_count <= n_bit_sent_count;
        flit_flag <= n_flit_flag;
    end
end

always_comb begin
        case (comma_sel) 
        SELECT_COMMA_1_FLIT :begin
                length_of_message = 'd2;
            end
        SELECT_COMMA_2_FLIT :begin
                length_of_message = 'd4;
            end
        SELECT_COMMA_DATA   :begin
                length_of_message = 'd10;
            end
        endcase

    n_bit_sent_count = bit_sent_count;
    n_flit_flag = 'b0;
    if (tx_err || done) begin
        n_bit_sent_count = 'b0;
    end
    else if (clk_flag) begin
        if (bit_sent_count == (length_of_message - 1'd1)) begin
            n_clk_flag = 1'b1;
            n_bit_sent_count = bit_sent_count + 1;
        end
        else if (bit_sent_count == length_of_message) begin
            n_bit_sent_count = 'b1;
        end
        else begin
            n_bit_sent_count = bit_sent_count + 1;
        end
    end
end



//Control Unit
typedef enum logic[1:0] {IDLE,START,SENDING,DONE,ERROR}uart_state;
uart_state state, n_state;
always_ff @(posedge CLK, negedge nRST) begin
    if ( ~nRST) begin
        state <= IDLE;
    end
    else begin
        state <= n_state;
    end
end

always_comb begin
    n_state = state;
    shift_en = 1'b0;
    done = 1'b0;
    case (state)
    IDLE: begin
        uart_out = '1;
        if (start) begin
            n_state = START;
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
        clk_en = 1'b1;
        shift_en = 1'b0;
        uart_out = shift_reg[(PORTCOUNT -1):0];
        
        if (clk_flag) begin
            shift_en = 1'b1;
        end
        
        if (start) begin
            n_state = ERROR;
        end
        else if (flit_flag) begin
            shift_en = 1'b1;
        end 
    end
    DONE: begin
        done = 1'b1;
        clk_en = 1'b1;
        uart_out = '1;
        shift_en = 'd0;
        if ( clk_flag && start) begin
            n_state = START; 
        end
        else if (start) begin
            n_state = ERROR;
        end 
        else if (clk_flag) begin
            n_state = IDLE;
        end
    end
    endcase

end

endmodule
