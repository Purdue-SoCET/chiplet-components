


module uart_rx # (parameter PORTCOUNT =5, parameter CLKDIV_W = 10, CLKDIV_COUNT ='d10 )
                 (input logic clk, nRST,
                  input logic [(PORTCOUNT -1):0] uart_in,
                  output logic [(PORTCOUNT * 10 -1):0] data,
                  output logic [1:0] comma_sel,
                  output logic done, rx_err);

parameter SELECT_COMMA_1_FLIT = 2'b1;
parameter SELECT_COMMA_2_FLIT = 2'd2;
parameter SELECT_COMMA_DATA   = 2'd3;
logic message_done = & sync_bits[1][(PORTCOUNT -1):0] && clk_flag;
logic start =  ~(& sync_bits[1][(PORTCOUNT -1):0]);

//uart sync
logic [1:0][(PORTCOUNT -1):0]sync_bits;

always_ff @(posedge clk, negedge nRST) begin
    if (~nRST) begin
        sync_bits <= '1;
    end
    else begin
        sync_bits <= {sync_bits[0],uart_in};
    end
end

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
    data = '1;
    if (tx_err) begin
        n_shift_reg ='1;
    end
    else if (message_done) begin
        n_shift_reg = '1;
        if (comma_sel ==SELECT_COMMA_1_FLIT) begin
            data = {(PORTCOUNT * 10 - 1)'0,shift_reg[9:0]};
            
        end
        else if (comma_sel == SELECT_COMMA_2_FLIT) begin
            data = {(PORTCOUNT * 10 - 1)'0,shift_reg[19:0]};
        end

        else begin
            data = shift_reg;
        end
    end
    else if (shift_en) begin
        n_shift_reg = {uart_in,shift_reg[(PORTCOUNT * 9 - 1):0]}
    end
end


//clk div
logic [(CLKDIV_W - 1):0]clk_div_count, n_clk_div_count;
logic clk_flag, n_clk_flag,clk_en;
always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        clk_div_count <= 'd(CLKDIV_COUNT/2);
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
    if (tx_err || message_done) begin
        n_clk_div_count = 'd0;
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
logic [4:0]bit_sent_count, n_bit_sent_count;
logic clk_flag, n_flit_flag;
logic [3:0] length_of_message;

always_ff @(posedge CLK, negedge nRST) begin
    if (~nRST) begin
        bit_sent_count <= 'd31;
    end
    else  begin
        bit_sent_count <= n_bit_sent_count;
    end
end

always_comb begin
    length_of_message = 'd0;

    n_bit_sent_count = bit_sent_count;
    if (tx_err || message_done) begin
        n_bit_sent_count = 'd31;
    end
    else if (clk_flag) begin
            n_bit_sent_count = bit_sent_count + 1;
    end
end

//fsm
typedef enum logic [3:0]{IDLE, RECIEVE, ERROR,DONE} rx_states;
rx_states state , n_state;
always_ff @(posedge clk, negedge nRST) begin
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
                n_state = RECIEVE;
            end
        end
        RECIEVE: begin
            clk_en = 1'b1;

            if(message_done) begin
                if(bit_sent_count == 'd3 || bit_sent_count == 'd5 || bit_sent_count == 'd11) begin
                    n_state = DONE;
                end
                else begin
                    n_state = ERROR;
                end

            end
            if(start) begin
                n_state = DONE;
            end 
        end
        DONE:
        begin
            done = 1'b1;
            n_state = IDLE;
            case(bit_sent_count)
            'd3: comma_sel = SELECT_COMMA_1_FLIT;
            'd5: comma_sel = SELECT_COMMA_2_FLIT;
            'd11: comma_sel = SELECT_COMMA_11_FLIT;
            default: n_state = ERROR;
            endcase
        end
        
        ERROR: begin
            rx_err = 1'b1;
            if(start) begin
                n_state = RECIEVE;
            end
        end

    endcase

end
endmodule
