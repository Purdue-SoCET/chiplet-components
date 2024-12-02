`ifndef BUFFERS_VH
`define BUFFERS_VH

`include "chiplet_types_pkg.vh"

interface buffers_if #(
    parameter int NUM_BUFFERS, /* Assumed to be the same across links */
    parameter int DEPTH
);
    import chiplet_types_pkg::*;

    flit_t [NUM_BUFFERS-1:0] wdata, rdata;
    logic [NUM_BUFFERS-1:0] WEN, REN, clear,
    logic [NUM_BUFFERS-1:0] full, empty, underrun, overrun
    logic [$clog2(DEPTH+1)-1:0] [NUM_BUFFERS-1:0] count,


    modport buffs(
        input wdata, WEN, REN, clear, 
        output rdata, full, empty, underrun, overrun, count
    );
endinterface

`endif //SWITCH_VH