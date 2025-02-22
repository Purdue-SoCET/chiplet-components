`include "chiplet_types_pkg.vh"

module req_fifo#(
    parameter DEPTH = 16
) (
    input logic clk, n_rst,
    input logic crc_valid,
    input [6:0] metadata,
    output logic overflow,
    bus_protocol_if.peripheral_vital bus_if
);

    localparam COUNT_ADDR = 32'h00;
    localparam OVERRUN_ADDR = 32'h04;
    localparam UNDERRUN_ADDR = 32'h08;
    localparam REN_ADDR = 32'h0C;
    localparam CLEAR_ADDR = 32'h10;

    logic ren, underrun, clear;
    node_id_t fifo_read;
    logic [$clog2(DEPTH):0] count;

    socetlib_fifo #(
        .T(logic[6:0]),
        .DEPTH(DEPTH)
    ) requestor_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(crc_valid),
        .REN(ren),
        .wdata(metadata),
        .clear(clear),
        .full(),
        .empty(),
        .underrun(underrun),
        .overrun(overflow),
        .count(count),
        .rdata(fifo_read)
    );

    always_comb begin
        ren = 0;
        clear = 0;
        bus_if.rdata = 0;
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
