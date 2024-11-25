`ifndef ROUTE_COMPUTE_VH
`define ROUTE_COMPUTE_VH

`include "chiplet_types_pkg.vh"

interface route_compute_if #(
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS
);

    import chiplet_types_pkg::*;

    flit_t [NUM_BUFFERS-1:0] in_flit;
    logic [$clog2(NUM_BUFFERS)-1:0] buffer_sel;
    logic [NUM_OUTPORTS-1:0] [$clog2(NUM_BUFFERS)-1:0] out_sel;
    logic [NUM_BUFFERS-1:0] allocate;

    //TODO 
    modport route(
        input in_flit,
        input buffer_sel,
        output allocate,
        output out_sel
    );
endinterface

`endif //ROUTE_COMPUTE_VH