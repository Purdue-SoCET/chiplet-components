`include "chiplet_types_pkg.vh"

module req_fifo#(
    parameter DEPTH = 16
) (
    input logic clk, n_rst,
    input logic crc_valid,
    input node_id_t req,
    output logic overflow,
    bus_protocol_if.peripheral_vital bus_if
);

    localparam COUNT_ADDR = 32'h3400;
    localparam OVERRUN_ADDR = 32'h3404;
    localparam UNDERRUN_ADDR = 32'h3408;
    localparam REN_ADDR = 32'h340C;
    localparam CLEAR_ADDR = 32'h3410;

    logic ren, underrun, clear;
    node_id_t fifo_read, count;

    socetlib_fifo #(.T(logic[4:0]), .DEPTH(DEPTH)) requestor_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(crc_valid),
        .REN(ren),
        .wdata(req),
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
                bus_if.rdata = {27'd0, count};
            end
            OVERRUN_ADDR: begin
                bus_if.rdata = {31'd0,overflow};
            end
            UNDERRUN_ADDR: begin
                bus_if.rdata = {31'd0,underrun};
            end
            REN_ADDR: begin
                ren = 1;
                bus_if.rdata = {27'd0, fifo_read};
            end
            CLEAR_ADDR: begin
                clear = 1;
                bus_if.rdata = {31'd0, clear};
            end
            default : begin end
        endcase
    end
end


endmodule
