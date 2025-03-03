/*
* notes on uart:
*   when transmiting send data at same time as start bit
*   comma sel determines the size use defined parameters in module to determine select comma value
*/

`timescale 1ns / 10ps

`include "uart_rx_if.sv"

module uart_tx #(
    parameter PORTCOUNT = 5,
    parameter CLKDIV_COUNT = 10
) (
    input logic CLK, nRST,
    uart_tx_if.tx tx_if
);
    import phy_types_pkg::*;

    //shift reg
    logic shift_en;
    logic [PORTCOUNT- 1:0] shift_reg_out;
    comma_length_sel_t comma_sel_reg, n_comma_sel_reg;
    logic byte_flag;
    genvar i;
    generate
        for (i = 0; i < PORTCOUNT; i = i +1) begin : shift_reg_block
        socetlib_shift_reg #(
            .NUM_BITS(10),
            .SHIFT_MSB(1)
        ) sr (
            .clk(CLK),
            .nRST(nRST),
            .shift_enable(shift_en),
            .parallel_load(tx_if.start),
            .serial_in('1),
            .parallel_in({
                tx_if.data[9 * PORTCOUNT + i],
                tx_if.data[8 * PORTCOUNT + i],
                tx_if.data[7 * PORTCOUNT + i],
                tx_if.data[6 * PORTCOUNT + i],
                tx_if.data[5 * PORTCOUNT + i],
                tx_if.data[4 * PORTCOUNT + i],
                tx_if.data[3 * PORTCOUNT + i],
                tx_if.data[2 * PORTCOUNT + i],
                tx_if.data[PORTCOUNT  + i],
                tx_if.data[i]
            }),
            .parallel_out(),
            .serial_out(shift_reg_out[i])
        );
        end
    endgenerate

    logic clk_flag, clk_en;
    socetlib_counter #(
        .NBITS($clog2(CLKDIV_COUNT))
    ) clk_count (
        .CLK(CLK),
        .nRST(nRST),
        .clear(tx_if.tx_err),
        .overflow_val(CLKDIV_COUNT),
        .count_enable(clk_en),
        .count_out(),
        .overflow_flag(clk_flag)
    );
    //clk div
    //bit sent counter
    logic [3:0] length_of_message;

    socetlib_counter #(
        .NBITS(4)
    ) bit_count (
        .CLK(CLK),
        .nRST(nRST),
        .clear(tx_if.tx_err || tx_if.done),
        .count_enable(clk_flag),
        .overflow_val(length_of_message),
        .count_out(),
        .overflow_flag(byte_flag)
    );

    always_comb begin
        length_of_message = '0;
        case (comma_sel_reg)
            SELECT_COMMA_1_FLIT: begin
                length_of_message = 4'd3;
            end
            SELECT_COMMA_2_FLIT: begin
                length_of_message = 4'd5;
            end
            SELECT_COMMA_DATA: begin
                length_of_message = 4'd11;
            end
            default: begin
                length_of_message = 4'd15;
            end
        endcase
    end

    //Control Unit
    typedef enum logic[2:0] {IDLE, START, SENDING, DONE, ERROR} uart_state;
    uart_state state, n_state;
    always_ff @(posedge CLK, negedge nRST) begin
        if (~nRST) begin
            state <= IDLE;
            comma_sel_reg <= NADA;
        end
        else begin
            state <= n_state;
            comma_sel_reg <= n_comma_sel_reg;
        end
    end

    // next state logic
    always_comb begin
     n_state = state;
        case (state)
            IDLE: begin
                if (tx_if.start) begin
                    n_state = START;
                end
            end
            START: begin
                if (tx_if.start) begin
                    n_state = ERROR;
                end
                else if (clk_flag) begin
                    n_state = SENDING;
                end
            end
            SENDING: begin
                if (tx_if.start) begin
                    n_state = ERROR;
                end
                else if (byte_flag) begin
                    n_state = DONE;
                end
            end
            DONE: begin
                if (clk_flag) begin
                    n_state = IDLE;
                end
                else if (tx_if.start) begin
                    n_state = ERROR;
                end
            end
            ERROR: begin
                if (tx_if.start) begin
                    n_state = START;
                end
            end
            default: begin
                n_state = state;
            end
        endcase
    end

    always_comb begin
        shift_en = 1'b0;
        tx_if.done = 1'b0;
        tx_if.uart_out = '1;
        n_comma_sel_reg = comma_sel_reg;
        clk_en = '0;
        tx_if.tx_err = '0;
        casez (state)
            IDLE: begin
                tx_if.uart_out = '1;
                if (tx_if.start) begin
                    n_comma_sel_reg = tx_if.comma_sel;
                end
            end
            START: begin
                clk_en = 1'b1;
                tx_if.uart_out = '0;
            end
            SENDING: begin
                tx_if.uart_out = shift_reg_out;
                clk_en = 1'b1;
                if (clk_flag) begin
                    shift_en = 1'b1;
                end
                if (byte_flag && ~tx_if.start) begin
                    shift_en = 1'b1;
                end
            end
            DONE: begin
                clk_en = 1'b1;
                shift_en = 'b0;
                tx_if.uart_out = '1;
                if (clk_flag) begin
                    tx_if.done = '1;
                end
            end
            ERROR: begin
                tx_if.tx_err = '1;
            end
            default: begin
                shift_en = 1'b0;
                tx_if.done = 1'b0;
                tx_if.uart_out = '1;
                n_comma_sel_reg = comma_sel_reg;
                clk_en = '0;
                tx_if.tx_err = '0;
            end
        endcase
    end
endmodule
