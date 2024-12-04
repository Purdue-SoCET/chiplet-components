`ifndef BUFFERS_VH
`define BUFFERS_VH

`include "chiplet_types_pkg.vh"

interface buffers_if #(
    parameter int NUM_BUFFERS, /* Assumed to be the same across links */
    parameter int DEPTH
);
    import chiplet_types_pkg::*;

    flit_t [NUM_BUFFERS-1:0] wdata, rdata;
    logic [NUM_BUFFERS-1:0] WEN, REN, valid;

    modport buffs(
        input wdata, WEN, REN,
        output rdata, valid
    );
endinterface

`endif //SWITCH_VH
