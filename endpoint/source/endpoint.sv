`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_if.vh"
`include "message_table_if.sv"

module endpoint #(
    parameter NUM_MSGS=4,
    parameter NODE_ID,
    parameter DEPTH
) (
    input logic clk, n_rst,
    switch_if.endpoint switch_if,
    bus_protocol_if.peripheral_vital bus_if
);
    import chiplet_types_pkg::*;

    localparam CACHE_NUM_WORDS = 128;
    localparam ADDR_WIDTH = $clog2(CACHE_NUM_WORDS) + 2;
    localparam CACHE_ADDR_LEN = CACHE_NUM_WORDS * 4;
    localparam PKT_ID_ADDR_ADDR_LEN = NUM_MSGS * 4;
    localparam TX_SEND_ADDR = 32'h1004;
    localparam TX_CACHE_START_ADDR = 32'h2000;
    localparam TX_CACHE_END_ADDR = TX_CACHE_START_ADDR + CACHE_ADDR_LEN;
    localparam RX_CACHE_START_ADDR = 32'h3000;
    localparam RX_CACHE_END_ADDR = RX_CACHE_START_ADDR + CACHE_ADDR_LEN;

    logic [NUM_MSGS-1:0] [ADDR_WIDTH-1:0] next_pkt_start_addr;

    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) tx_bus_if();
    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) tx_cache_if();
    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) rx_bus_if();
    message_table_if #(.NUM_MSGS(NUM_MSGS)) msg_if();
    tx_fsm_if #(.NUM_MSGS(NUM_MSGS), .ADDR_WIDTH(ADDR_WIDTH)) tx_fsm_if();

    cache #(.NUM_WORDS(CACHE_NUM_WORDS)) tx_cache(
        .clk(clk),
        .n_rst(n_rst),
        .in_flit(flit_t'('0)),
        .data_ready(1'b0),
        .bus_if(tx_bus_if)
    );

    cache #(.NUM_WORDS(CACHE_NUM_WORDS), .RX(1'b1)) rx_cache(
        .clk(clk),
        .n_rst(n_rst),
        .in_flit(switch_if.out[0]),
        .data_ready(switch_if.data_ready_out[0]),
        .bus_if(rx_bus_if)
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
    ) tx(
        .clk(clk),
        .n_rst(n_rst),
        .tx_if(tx_fsm_if),
        .switch_if(switch_if),
        .tx_cache_if(tx_cache_if),
        .msg_if(msg_if)
    );

    // TODO:
    assign tx_fsm_if.node_id = NODE_ID;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            tx_fsm_if.pkt_start_addr <= '0;
        end else begin
            tx_fsm_if.pkt_start_addr <= next_pkt_start_addr;
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
        bus_if.rdata = 32'hBAD1BAD1;
        bus_if.error = 0;
        bus_if.request_stall = 0;
        next_pkt_start_addr = tx_fsm_if.pkt_start_addr;
        msg_if.trigger_send = '0;

        if (tx_cache_if.ren || tx_cache_if.wen) begin
            tx_bus_if.wen = tx_cache_if.wen;
            tx_bus_if.ren = tx_cache_if.ren;
            tx_bus_if.addr = tx_cache_if.addr[8:0];
            tx_cache_if.rdata = tx_bus_if.rdata;
            tx_cache_if.error = tx_bus_if.error;
            tx_cache_if.request_stall = tx_bus_if.request_stall;
        end

        // TODO: what's the best way to route this, I want to define maps,
        // send them to whereever they need to go, and have this logic there
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
            if (!(tx_cache_if.ren || tx_cache_if.wen)) begin
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
            rx_bus_if.ren = bus_if.ren;
            rx_bus_if.addr = bus_if.addr[8:0];
            rx_bus_if.wdata = bus_if.wdata;
            rx_bus_if.strobe = bus_if.strobe;
            bus_if.rdata = rx_bus_if.rdata;
            bus_if.error = rx_bus_if.wen;
            bus_if.request_stall = rx_bus_if.request_stall;
        end
    end
endmodule
