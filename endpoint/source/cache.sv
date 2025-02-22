`include "chiplet_types_pkg.vh"

module cache#(
    parameter NUM_WORDS=128
)(
    input logic clk, n_rst,
    bus_protocol_if.peripheral_vital bus_if
);
    import chiplet_types_pkg::*;

    localparam ADDR_LEN = $clog2(NUM_WORDS);

    word_t byte_en;

    // TODO: SRAM?
    word_t [NUM_WORDS-1:0] cache, next_cache;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            cache <= '0;
        end else begin
            cache <= next_cache;
        end
    end

    assign bus_if.rdata = bus_if.ren ? cache[bus_if.addr[2+:ADDR_LEN]] : 32'hBAD1BAD1;
    assign bus_if.request_stall = 0;

    // Expand byte_en to 32 bit signal
    always_comb begin
        for (int i = 0; i < 4; i = i + 1) begin
            byte_en[i*8+:8] = bus_if.strobe[i] ? 8'hFF : 8'h00;
        end
    end

    always_comb begin
        next_cache = cache;
        if (bus_if.wen) begin
            next_cache[bus_if.addr[2+:ADDR_LEN]] = bus_if.wdata & byte_en;
        end
    end
endmodule
