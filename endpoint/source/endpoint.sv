`timescale 1ns / 10ps

module endpoint #(
    // parameters
) (
    input logic clk, n_rst,
    bus_protocol_if.peripheral_vital bus_if
);
    localparam CACHE_NUM_WORDS = 128;
    localparam ADDR_WIDTH = $clog2(CACHE_NUM_WORDS) + 2;

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
        // TX cache
        if (bus_if.addr >= 32'h2000 && bus_if.addr < 32'h2200) begin
            tx_bus_if.wen = bus_if.wen;
            tx_bus_if.ren = bus_if.ren;
            tx_bus_if.addr = bus_if.addr[8:0];
            tx_bus_if.wdata = bus_if.wdata;
            tx_bus_if.strobe = bus_if.strobe;
            bus_if.rdata = tx_bus_if.rdata;
            bus_if.error = tx_bus_if.error;
            bus_if.request_stall = tx_bus_if.request_stall;
        // RX cache
        end else if (bus_if.addr >= 32'h3000 && bus_if.addr < 32'h3200) begin
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
