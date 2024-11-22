`ifndef ROUTE_COMPUTE_VH
`define ROUTE_COMPUTE_VH

`include "chiplet_types_pkg.vh"

interface route_compute_if #(
    parameter BUFFERS
);

    import chiplet_types_pkg::*;

    flit_t [BUFFERS-1:0] in_flit;
    logic [$clog2(BUFFERS)-1:0] buffer_sel, out_sel;


    //TODO 
    modport route(
        input in_flit,
        input buffer_sel,
        output id,
        output out_sel
    );
endinterface

`endif //ROUTE_COMPUTE_VH