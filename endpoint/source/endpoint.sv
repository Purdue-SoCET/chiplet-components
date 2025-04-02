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

    localparam CACHE_NUM_WORDS = 128;
    localparam ADDR_WIDTH = $clog2(4*CACHE_NUM_WORDS);
    localparam CACHE_ADDR_LEN = CACHE_NUM_WORDS * 4;
    localparam PKT_ID_ADDR_ADDR_LEN = NUM_MSGS * 4;
    localparam TX_WRITE_ADDR = 32'h0000;
    localparam TX_SEND_ADDR = 32'h0004;
    localparam RX_READ_ADDR = 32'h1000;
    localparam REQ_FIFO_START_ADDR = RX_READ_ADDR + 32'h100;
    localparam REQ_FIFO_END_ADDR = REQ_FIFO_START_ADDR + 32'h80;
    localparam CONFIG_DONE_ADDR = REQ_FIFO_START_ADDR + 32'h100;

    logic tx_fifo_wen, tx_fifo_full, tx_fifo_empty;
    logic rx_fifo_ren, rx_fifo_empty;
    chiplet_word_t tx_byte_en, rx_byte_en;
    logic [31:0] rx_fifo_rdata;

    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) rx_fifo_if();
    message_table_if #(.NUM_MSGS(NUM_MSGS)) msg_if();
    tx_fsm_if #(.NUM_MSGS(NUM_MSGS), .ADDR_WIDTH(ADDR_WIDTH)) tx_fsm_if();
    rx_fsm_if rx_if();

    req_fifo requestor_fifo(
        .clk(clk),
        .n_rst(n_rst),
        .packet_recv(packet_recv),
        .rx_if(rx_if),
        .bus_if(rx_fifo_if)
    );

    rx_fsm rx_fsm(
        .clk(clk),
        .n_rst(n_rst),
        .rx_if(rx_if),
        .endpoint_if(endpoint_if)
    );

    socetlib_fifo #(
        .WIDTH(32),
        .DEPTH(128)
    ) rx_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(rx_if.rx_fifo_wen),
        .REN(rx_fifo_ren),
        .wdata(endpoint_if.out.payload),
        .clear(1'b0),
        .full(),
        .empty(rx_fifo_empty),
        .underrun(),
        .overrun(),
        .count(),
        .rdata(rx_fifo_rdata)
    );

    // TODO: can we reduce the size of this?
    // Example flow would be trigger certain packet send then start spamming
    // flits. Just need to be careful about error conditions
    socetlib_fifo #(
        .WIDTH(32),
        .DEPTH(128)
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
        rx_fifo_if.ren = 0;
        rx_fifo_if.addr = 0;
        bus_if.rdata = 32'hBAD1BAD1;
        bus_if.error = 0;
        bus_if.request_stall = 0;
        msg_if.trigger_send = '0;
        tx_fifo_wen = 0;
        rx_fifo_ren = 0;

        // Message table
        if (bus_if.addr == TX_SEND_ADDR && bus_if.wen) begin
            if (!tx_fsm_if.busy) begin
                if (!tx_fifo_empty && bus_if.wdata < NUM_MSGS) begin
                    msg_if.trigger_send[bus_if.wdata] = 1;
                end else begin
                    bus_if.error = 1;
                end
            end else begin
                bus_if.request_stall = 1;
            end
        // TX cache
        end else if (bus_if.wen && bus_if.addr == TX_WRITE_ADDR) begin
            if (!tx_fifo_full) begin
                tx_fifo_wen = 1;
            end else begin
                bus_if.error = 1;
                bus_if.request_stall = 0;
            end
        // RX cache
        end else if (bus_if.ren && bus_if.addr == RX_READ_ADDR) begin
            if (!rx_fifo_empty) begin
                bus_if.rdata = rx_fifo_rdata;
                rx_fifo_ren = 1;
            end else begin
                bus_if.error = 1;
                bus_if.request_stall = 0;
            end
        end else if (bus_if.ren && bus_if.addr >= REQ_FIFO_START_ADDR && bus_if.addr < REQ_FIFO_END_ADDR) begin
            rx_fifo_if.ren = bus_if.ren;
            rx_fifo_if.addr = bus_if.addr[6:0];
            bus_if.rdata = rx_fifo_if.rdata;
        end else if (bus_if.addr == CONFIG_DONE_ADDR) begin
            bus_if.rdata = {31'd0, endpoint_if.config_done};
        end else if (bus_if.wen || bus_if.ren) begin
            bus_if.error = 1;
        end 
    end
endmodule
