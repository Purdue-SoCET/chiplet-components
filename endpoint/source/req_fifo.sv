`include "chiplet_types_pkg.vh"

module req_fifo#(
    parameter DEPTH = 16
) (
    input logic clk, n_rst,
    input logic crc_valid,
    input logic [6:0] metadata,
    output logic overflow,
    output logic packet_recv,
    bus_protocol_if.peripheral_vital bus_if
);
    import chiplet_types_pkg::*;

    localparam COUNT_ADDR = 32'h00;
    localparam OVERRUN_ADDR = 32'h04;
    localparam UNDERRUN_ADDR = 32'h08;
    localparam REN_ADDR = 32'h0C;
    localparam CLEAR_ADDR = 32'h10;

    logic ren, underrun, clear;
    logic [6:0] fifo_read;
    logic [$clog2(DEPTH):0] count;
    logic empty;

    socetlib_fifo #(
        .WIDTH(7),
        .DEPTH(DEPTH)
    ) requestor_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(crc_valid),
        .REN(ren),
        .wdata(metadata),
        .clear(clear),
        .full(),
        .empty(empty),
        .underrun(underrun),
        .overrun(overflow),
        .count(count),
        .rdata(fifo_read)
    );

    assign packet_recv = !empty;

    always_comb begin
        ren = 0;
        clear = 0;
        bus_if.rdata = 0;
        bus_if.error = 0;
        bus_if.request_stall = 0;
        if(bus_if.ren) begin
            casez(bus_if.addr)
                COUNT_ADDR: begin
                    bus_if.rdata = count;
                end
                OVERRUN_ADDR: begin
                    bus_if.rdata = overflow;
                end
                UNDERRUN_ADDR: begin
                    bus_if.rdata = underrun;
                end
                REN_ADDR: begin
                    ren = 1;
                    bus_if.rdata = fifo_read;
                end
                CLEAR_ADDR: begin
                    clear = 1;
                    bus_if.rdata = clear;
                end
                default : begin
                    bus_if.error = 1;
                end
            endcase
        end
    end
endmodule
