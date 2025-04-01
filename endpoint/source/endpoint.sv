`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_if.vh"
`include "message_table_if.sv"
`include "endpoint_if.sv"

module endpoint #(
    parameter NUM_MSGS=4,
    parameter DEPTH
) (
    input logic clk, n_rst,
    output logic packet_recv,
    endpoint_if endpoint_if,
    bus_protocol_if.peripheral_vital bus_if
);
    import chiplet_types_pkg::*;

    typedef enum logic { OFF, ON } fifo_state_e;

    localparam CACHE_NUM_WORDS = 128;
    localparam ADDR_WIDTH = $clog2(4*CACHE_NUM_WORDS);
    localparam CACHE_ADDR_LEN = CACHE_NUM_WORDS * 4;
    localparam PKT_ID_ADDR_ADDR_LEN = NUM_MSGS * 4;
    localparam TX_SEND_ADDR = 32'h1004;
    localparam TX_CACHE_START_ADDR = 32'h2000;
    localparam TX_CACHE_END_ADDR = TX_CACHE_START_ADDR + CACHE_ADDR_LEN;
    localparam RX_CACHE_START_ADDR = 32'h3000;
    localparam RX_CACHE_END_ADDR = RX_CACHE_START_ADDR + CACHE_ADDR_LEN;
    localparam REQ_FIFO_START_ADDR = 32'h3400;
    localparam REQ_FIFO_END_ADDR = REQ_FIFO_START_ADDR + 20;
    localparam CONFIG_DONE_ADDR = 32'h3500;

    logic enable, overflow, crc_valid, crc_error;
    logic [6:0] metadata;
    logic tx_fifo_wen, tx_fifo_full, tx_fifo_empty;
    logic rx_fifo_wen, rx_fifo_ren, rx_fifo_empty;
    fifo_state_e rx_fifo_state, next_rx_fifo_state;
    chiplet_word_t tx_byte_en, rx_byte_en;

    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) rx_bus_if();
    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) rx_cache_if();
    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) rx_fifo_if();
    message_table_if #(.NUM_MSGS(NUM_MSGS)) msg_if();
    tx_fsm_if #(.NUM_MSGS(NUM_MSGS), .ADDR_WIDTH(ADDR_WIDTH)) tx_fsm_if();

    req_fifo requestor_fifo(
        .clk(clk),
        .n_rst(n_rst),
        .crc_valid(enable),
        .metadata(metadata),
        .overflow(overflow),
        .packet_recv(packet_recv),
        .bus_if(rx_fifo_if)
    );

    rx_fsm rx_fsm(
        .clk(clk),
        .n_rst(n_rst),
        .overflow(overflow),
        .fifo_enable(enable),
        .metadata(metadata),
        .crc_error(crc_error),
        .endpoint_if(endpoint_if),
        .rx_cache_if (rx_cache_if)
    );

    socetlib_fifo #(
        .WIDTH(32),
        .DEPTH(8)
    ) rx_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(rx_fifo_wen),
        .REN(rx_fifo_ren),
        .wdata(endpoint_if.out.payload),
        .clear(1'b0),
        .full(),
        .empty(rx_fifo_empty),
        .underrun(),
        .overrun(),
        .count(),
        .rdata(bus_if.rdata)
    );

    // TODO: can we reduce the size of this?
    // Example flow would be trigger certain packet send then start spamming
    // flits. Just need to be careful about error conditions
    socetlib_fifo #(
        .WIDTH(32),
        .DEPTH(8)
    ) tx_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(tx_fifo_wen),
        .REN(tx_fsm_if.fifo_ren),
        .wdata(bus_if.wdata),
        .clear(1'b0),
        .full(tx_fifo_full),
        .empty(tx_fifo_empty),
        .underrun(),
        .overrun(),
        .count(),
        .rdata(tx_fsm_if.fifo_rdata)
    );

    message_table #(.NUM_MSGS(NUM_MSGS)) msg_table(
        .clk(clk),
        .n_rst(n_rst),
        .msg_if(msg_if)
    );

    tx_fsm #(
        .NUM_MSGS(NUM_MSGS),
        .TX_SEND_ADDR(TX_SEND_ADDR),
        .DEPTH(DEPTH)
    ) tx_fsm(
        .clk(clk),
        .n_rst(n_rst),
        .tx_if(tx_fsm_if),
        .endpoint_if(endpoint_if),
        .msg_if(msg_if)
    );

    assign tx_fsm_if.node_id = endpoint_if.node_id;

    always_comb begin
        rx_bus_if.wen = 0;
        rx_bus_if.ren = 0;
        rx_bus_if.addr = 0;
        rx_bus_if.wdata = 0;
        rx_bus_if.strobe = 0;
        rx_cache_if.rdata = 32'hBAD1BAD1;
        rx_cache_if.error = 0;
        rx_cache_if.request_stall = 0;
        rx_fifo_if.ren = 0;
        rx_fifo_if.addr = 0;
        bus_if.rdata = 32'hBAD1BAD1;
        bus_if.error = 0;
        bus_if.request_stall = 0;
        msg_if.trigger_send = '0;
        tx_fifo_wen = 0;
        rx_fifo_wen = 0;
        rx_fifo_ren = 0;

        // Message table
        if (bus_if.addr == TX_SEND_ADDR && bus_if.wen) begin
            if (!tx_fifo_empty && bus_if.wdata < NUM_MSGS) begin
                msg_if.trigger_send[bus_if.wdata] = 1;
            end else begin
                bus_if.error = 1;
            end
        // TX cache
        end else if (bus_if.wen && bus_if.addr >= TX_CACHE_START_ADDR && bus_if.addr < TX_CACHE_END_ADDR) begin
            if (!tx_fifo_full) begin
                tx_fifo_wen = 1;
            end else begin
                bus_if.error = 1;
                bus_if.request_stall = 0;
            end
        // RX cache
        end else if (bus_if.ren && bus_if.addr >= RX_CACHE_START_ADDR && bus_if.addr < RX_CACHE_END_ADDR) begin
            // TOOD: handle bus read from rx cache
            if (!rx_fifo_empty) begin
                rx_fifo_ren = 1;
            end else begin
                bus_if.error = 1;
                bus_if.request_stall = 0;
            end
        end else if (bus_if.addr >= REQ_FIFO_START_ADDR && bus_if.addr < REQ_FIFO_END_ADDR) begin
            rx_fifo_if.ren = bus_if.ren;
            rx_fifo_if.addr = bus_if.addr[8:0];
            bus_if.rdata = rx_fifo_if.rdata;
        end else if (bus_if.wen || bus_if.ren) begin
            bus_if.error = 1;
        end else if (bus_if.addr == CONFIG_DONE_ADDR) begin
            bus_if.rdata = {31'd0, endpoint_if.config_done};
        end

        // TODO: handle fsm write from rx cache
        /*
        if (rx_controller == FSM) begin
            rx_bus_if.wen = rx_cache_if.wen;
            rx_bus_if.wdata = rx_cache_if.wdata;
            rx_bus_if.ren = rx_cache_if.ren;
            rx_bus_if.addr = rx_cache_if.addr[8:0];
            rx_bus_if.strobe = '1;
            rx_cache_if.rdata = rx_bus_if.rdata;
            rx_cache_if.error = rx_bus_if.error;
            rx_cache_if.request_stall = rx_bus_if.request_stall;
        end else begin
            rx_cache_if.request_stall = 1;
        end
        */
    end
endmodule
