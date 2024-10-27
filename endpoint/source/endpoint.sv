`timescale 1ns / 10ps
`include "chiplet_types_pkg.vh"
`include "phy_manager_if.vh"
`include "message_table_if.vh"

module endpoint #(
    parameter NUM_MSGS=4
) (
    input logic clk, n_rst,
    bus_protocol_if.peripheral_vital bus_if
);
    import chiplet_types_pkg::*;

    localparam CACHE_NUM_WORDS = 128;
    localparam ADDR_WIDTH = $clog2(CACHE_NUM_WORDS) + 2;
    localparam CACHE_ADDR_LEN = CACHE_NUM_WORDS * 4;
    localparam PKT_ID_ADDR_ADDR_LEN = NUM_MSGS * 4;
    localparam TX_CACHE_START_ADDR = 32'h2000;
    localparam TX_CACHE_END_ADDR = TX_CACHE_START_ADDR + CACHE_ADDR_LEN;
    localparam RX_CACHE_START_ADDR = 32'h3000;
    localparam RX_CACHE_END_ADDR = RX_CACHE_START_ADDR + CACHE_ADDR_LEN;

    word_t [NUM_MSGS-1:0] pkt_start_addr, next_pkt_start_addr;

    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) tx_bus_if();
    bus_protocol_if #(.ADDR_WIDTH(ADDR_WIDTH)) rx_bus_if();

    cache #(.NUM_WORDS(CACHE_NUM_WORDS)) tx_cache(
        .clk(clk),
        .n_rst(n_rst),
        .bus_if(tx_bus_if)
    );

    cache #(.NUM_WORDS(CACHE_NUM_WORDS)) rx_cache(
        .clk(clk),
        .n_rst(n_rst),
        .bus_if(rx_bus_if)
    );

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            pkt_start_addr <= '0;
        end else begin
            pkt_start_addr <= next_pkt_start_addr;
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
        bus_if.rdata = 32'hBAD1BAD1;
        bus_if.error = 0;
        bus_if.request_stall = 0;
        next_pkt_start_addr = pkt_start_addr;

        // TODO: what's the best way to route this, I want to define maps,
        // send them to whereever they need to go, and have this logic there
        if (bus_if.addr < PKT_ID_ADDR_ADDR_LEN) begin
            if (bus_if.ren) begin
                bus_if.rdata = pkt_start_addr[bus_if.addr[2+:$clog2(NUM_MSGS)]];
            end else if (bus_if.wen) begin
                next_pkt_start_addr[bus_if.addr[2+:$clog2(NUM_MSGS)]] = bus_if.wdata[0+:ADDR_WIDTH] & ~'h3;
            end
        // TX cache
        end else if (bus_if.addr >= TX_CACHE_START_ADDR && bus_if.addr < TX_CACHE_END_ADDR) begin
            tx_bus_if.wen = bus_if.wen;
            tx_bus_if.ren = bus_if.ren;
            tx_bus_if.addr = bus_if.addr[8:0];
            tx_bus_if.wdata = bus_if.wdata;
            tx_bus_if.strobe = bus_if.strobe;
            bus_if.rdata = tx_bus_if.rdata;
            bus_if.error = tx_bus_if.error;
            bus_if.request_stall = tx_bus_if.request_stall;
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
