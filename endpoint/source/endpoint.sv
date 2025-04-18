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

    typedef enum logic { FSM, BUS } cache_controller_e;

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

    logic [NUM_MSGS-1:0] [ADDR_WIDTH-1:0] next_pkt_start_addr;
    logic enable, overflow, crc_valid, crc_error;
    logic [6:0] metadata;
    cache_controller_e rx_controller, next_rx_controller, tx_controller, next_tx_controller;

    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) tx_bus_if();
    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) tx_cache_if();
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

    cache #(.NUM_WORDS(CACHE_NUM_WORDS)) rx_cache(
        .clk(clk),
        .n_rst(n_rst),
        .bus_if(rx_bus_if)
    );

    cache #(.NUM_WORDS(CACHE_NUM_WORDS)) tx_cache(
        .clk(clk),
        .n_rst(n_rst),
        .bus_if(tx_bus_if)
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
        .tx_cache_if(tx_cache_if),
        .msg_if(msg_if)
    );

    assign tx_fsm_if.node_id = endpoint_if.node_id;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            tx_fsm_if.pkt_start_addr <= '0;
            rx_controller <= BUS;
            tx_controller <= BUS;
        end else begin
            tx_fsm_if.pkt_start_addr <= next_pkt_start_addr;
            rx_controller <= next_rx_controller;
            tx_controller <= next_tx_controller;
        end
    end

    always_comb begin
        tx_bus_if.wen = 0;
        tx_bus_if.ren = 0;
        tx_bus_if.addr = 0;
        tx_bus_if.wdata = 0;
        tx_bus_if.strobe = 0;
        rx_bus_if.wen = 0;
        rx_bus_if.ren = 0;
        rx_bus_if.addr = 0;
        rx_bus_if.wdata = 0;
        rx_bus_if.strobe = 0;
        tx_cache_if.rdata = 32'hBAD1BAD1;
        tx_cache_if.error = 0;
        tx_cache_if.request_stall = 0;
        rx_cache_if.rdata = 32'hBAD1BAD1;
        rx_cache_if.error = 0;
        rx_cache_if.request_stall = 0;
        rx_fifo_if.ren = 0;
        rx_fifo_if.addr = 0;
        bus_if.rdata = 32'hBAD1BAD1;
        bus_if.error = 0;
        bus_if.request_stall = 0;
        next_pkt_start_addr = tx_fsm_if.pkt_start_addr;
        msg_if.trigger_send = '0;
        next_rx_controller = (rx_cache_if.ren || rx_cache_if.wen) ? FSM : BUS;
        next_tx_controller = (tx_cache_if.ren || tx_cache_if.wen) ? FSM : BUS;

        if (bus_if.addr < PKT_ID_ADDR_ADDR_LEN) begin
            if (bus_if.ren) begin
                bus_if.rdata = tx_fsm_if.pkt_start_addr[bus_if.addr[2+:$clog2(NUM_MSGS)]];
            end else if (bus_if.wen) begin
                next_pkt_start_addr[bus_if.addr[2+:$clog2(NUM_MSGS)]] = bus_if.wdata[0+:ADDR_WIDTH] & ~'h3;
            end
        // Message table
        end else if (bus_if.addr == TX_SEND_ADDR && bus_if.wen) begin
            if (bus_if.wdata < NUM_MSGS) begin
                msg_if.trigger_send[bus_if.wdata] = 1;
            end else begin
                bus_if.error = 1;
            end
        // TX cache
        end else if (bus_if.addr >= TX_CACHE_START_ADDR && bus_if.addr < TX_CACHE_END_ADDR) begin
            if (tx_controller == BUS) begin
                tx_bus_if.wen = bus_if.wen;
                tx_bus_if.ren = bus_if.ren;
                tx_bus_if.addr = bus_if.addr[8:0];
                tx_bus_if.wdata = bus_if.wdata;
                tx_bus_if.strobe = bus_if.strobe;
                bus_if.rdata = tx_bus_if.rdata;
                bus_if.error = tx_bus_if.error;
                bus_if.request_stall = tx_bus_if.request_stall;
            end else begin
                bus_if.request_stall = 1;
            end
        // RX cache
        end else if (bus_if.addr >= RX_CACHE_START_ADDR && bus_if.addr < RX_CACHE_END_ADDR) begin
            if (rx_controller == BUS) begin
                rx_bus_if.wen = 0;
                rx_bus_if.ren = bus_if.ren;
                rx_bus_if.addr = bus_if.addr[8:0];
                rx_bus_if.wdata = bus_if.wdata;
                rx_bus_if.strobe = bus_if.strobe;
                bus_if.rdata = rx_bus_if.rdata;
                bus_if.error = rx_bus_if.error;
                bus_if.request_stall = rx_bus_if.request_stall;
            end else begin
                bus_if.request_stall = 1;
            end
        end else if (bus_if.addr >= REQ_FIFO_START_ADDR && bus_if.addr < REQ_FIFO_END_ADDR) begin
            rx_fifo_if.ren = bus_if.ren;
            rx_fifo_if.addr = bus_if.addr[8:0];
            bus_if.rdata = rx_fifo_if.rdata;
        end else if (bus_if.wen || bus_if.ren) begin
            bus_if.error = 1;
        end

        if (tx_controller == FSM) begin
            tx_bus_if.wen = tx_cache_if.wen;
            tx_bus_if.ren = tx_cache_if.ren;
            tx_bus_if.addr = tx_cache_if.addr[8:0];
            tx_cache_if.rdata = tx_bus_if.rdata;
            tx_cache_if.error = tx_bus_if.error;
            tx_cache_if.request_stall = tx_bus_if.request_stall;
        end else begin
            tx_cache_if.request_stall = 1;
        end

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
    end
endmodule
