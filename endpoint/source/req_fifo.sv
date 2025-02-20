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

    logic ren, underrun, next_overflow;
    node_id_t next_rdata, rdata, fifo_read, count;

    typedef enum logic [1:0]
    {
        COUNT,
        OVERRUN,
        UNDERRUN,
        REN
    };

    socetlib_fifo #(.T(logic[4:0]), .DEPTH(DEPTH)) requestor_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(crc_valid),
        .REN(ren),
        .wdata(req),
        .underrun(underrun),
        .overrun(overflow),
        .count(count),
        .rdata(fifo_read),
    );

always_ff @(posedge clk, negedge n_rst) begin
    if(!n_rst) begin
        rdata <= '0;
    end 
    else begin
        rdata <= next_rdata;
    end
end

always_comb begin
    next_rdata = '0;
    ren = 0;

    if(bus_if.ren) begin
        casez(bus_if.addr)
            COUNT: begin
                next_rdata = count;
            end
            OVERRUN: begin
                next_rdata = overflow;
            end
            UNDERRUN: begin
                next_rdata = underrun;
            end
            REN: begin
                ren = 1'b1;
                next_rdata = fifo_read;
            end
        endcase
    end
end


endmodule