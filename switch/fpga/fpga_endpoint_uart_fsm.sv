module fpga_endpoint_uart_fsm #(
    parameter FREQUENCY=50_000_000,
    parameter EXPECTED_BAUD_RATE = 9600
)(
    input logic clk, n_rst,
    input logic serial_in,
    bus_protocol_if.protocol bus_if
);
    import phy_types_pkg::*;

    localparam CLKDIV_COUNT = FREQUENCY / EXPECTED_BAUD_RATE;

    uart_rx_if #(.PORTCOUNT(1)) rx_if();

    logic message_done, start,clk_en,sent_flag,shift_en, clk_flag;
    logic sync_out;
    logic [3:0]bit_sent_count;
    typedef enum logic [3:0]{IDLE, RECIEVE, ERROR,DONE, START} rx_states;

    typedef enum logic [2:0] {
        IDLE_BUS,
        ADDR,
        DATA,
        SEND
    } bus_state_e;

    bus_state_e bus_state, next_bus_state;
    logic read_nwrite, next_read_nwrite;
    logic word_count_en, word_clear;
    logic [3:0] word_count;
    word_t next_addr, next_wdata;
    rx_states state, n_state;

    logic [7:0] data;

    assign message_done = bit_sent_count == 8;
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
        .serial_in(sync_out),
        .parallel_load(0),
        .parallel_in('1),
        .serial_out(),
        .parallel_out(data)
    );

    rx_timer #(
        .NBITS($clog2(CLKDIV_COUNT)),
        .COUNT_TO(CLKDIV_COUNT)
    ) clk_count (
        .CLK(clk),
        .nRST(n_rst),
        .clear(rx_if.rx_err),
        .count_enable(clk_en),
        .overflow_flag(clk_flag)
    );

    //clk div
    //bit sent counter
    socetlib_counter #(
        .NBITS(4)
    ) bit_count (
        .CLK(clk),
        .nRST(n_rst),
        .clear(state == IDLE),
        .count_enable(clk_flag && state == RECIEVE),
        .overflow_val(4'd8),
        .count_out(bit_sent_count),
        .overflow_flag(sent_flag)
    );

    socetlib_counter #(
        .NBITS(4)
    ) word_counter (
        .CLK(clk),
        .nRST(n_rst),
        .clear(word_clear),
        .count_enable(word_count_en),
        .overflow_val(4'd4),
        .count_out(word_count),
        .overflow_flag(word_done)
    );

    //fsm
    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            state <= IDLE;
            bus_state <= IDLE_BUS;
            read_nwrite <= 1;
            bus_if.addr <= 0;
            bus_if.wdata <= 0;
        end else begin
            state <= n_state;
            bus_state <= next_bus_state;
            read_nwrite <= next_read_nwrite;
            bus_if.addr <= next_addr;
            bus_if.wdata <= next_wdata;
        end
    end

    // UART FSM update
    always_comb begin
        n_state = state;
        case(state)
            IDLE: begin
                if (start) begin
                    n_state = START;
                end
            end
            START: begin
                if (clk_flag) begin
                    n_state = RECIEVE;
                end else if (message_done || start != '1) begin
                    n_state = ERROR;
                end
            end
            RECIEVE: begin
                if (clk_flag && start) begin
                    n_state = ERROR;
                end else if (message_done && clk_flag) begin
                    if (bit_sent_count == 4'd8) begin
                        n_state = DONE;
                    end
                    else begin
                        n_state = ERROR;
                    end
                end
            end
            DONE: begin
                n_state = IDLE;
            end
            ERROR: begin
                if(start) begin
                    n_state = START;
                end
            end
            default: begin end
        endcase
    end

    // UART FSM logic
    always_comb begin
        rx_if.comma_sel = NADA;
        clk_en = '0;
        shift_en ='0;
        rx_if.done = '0;
        rx_if.rx_err = '0;
        case(state)
            START: begin
                clk_en = '1;
            end
            RECIEVE: begin
                clk_en = 1'b1;
                if (clk_flag && ~message_done && ~start) begin
                    shift_en = 1'b1;
                end
            end
            DONE: begin
                rx_if.done = '1;
                clk_en = '1;
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

    // Bus update
    always_comb begin
        next_bus_state = bus_state;

        case (bus_state)
            IDLE_BUS : begin
                if (rx_if.done) begin
                    next_bus_state = ADDR;
                end
            end
            ADDR : begin
                if (word_done) begin
                    next_bus_state = DATA;
                end
            end
            DATA : begin
                if (word_done) begin
                    next_bus_state = SEND;
                end
            end
            SEND : begin
                if (!bus_if.request_stall) begin
                    next_bus_state = IDLE_BUS;
                end
            end
        endcase
    end

    // Bus logic
    always_comb begin
        next_read_nwrite = read_nwrite;
        word_count_en = 0;
        word_clear = 0;
        next_addr = bus_if.addr;
        next_wdata = bus_if.wdata;
        bus_if.strobe = '1;
        bus_if.wen = 0;
        bus_if.ren = 0;

        case (bus_state)
            IDLE_BUS : begin
                if (rx_if.done) begin
                    next_read_nwrite = data;
                    word_clear = 1;
                end
            end
            ADDR : begin
                if (rx_if.done) begin
                    next_addr[word_count*8+:8] = data;
                    word_count_en = 1;
                end
                if (word_done) begin
                    word_clear = 1;
                end
            end
            DATA : begin
                if (rx_if.done) begin
                    next_wdata[word_count*8+:8] = data;
                    word_count_en = 1;
                end
                if (word_done) begin
                    word_clear = 1;
                end
            end
            SEND : begin
                bus_if.ren = read_nwrite;
                bus_if.wen = !read_nwrite;
            end
        endcase
    end
endmodule
