`ifndef ROUTE_COMPUTE_VH
`define ROUTE_COMPUTE_VH

`include "chiplet_types_pkg.vh"
`include "switch_pkg.sv"

interface route_compute_if #(
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS,
    parameter TABLE_SIZE
);
    import chiplet_types_pkg::*;
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_OUTPORTS) + (NUM_OUTPORTS == 1);

    flit_t [NUM_BUFFERS-1:0] in_flit;
    route_lut_t [TABLE_SIZE-1:0] route_lut;
    // logic [$clog2(NUM_BUFFERS)-1:0] buffer_sel;
    // The requested outport for each buffer. Buffers may have the same
    // requested outport, but the switch allocator will arbitrate
    logic [NUM_BUFFERS-1:0] [SELECT_SIZE-1:0] out_sel;
    logic [NUM_BUFFERS-1:0] allocate;

    //TODO 
    modport route(
        input in_flit,
        input route_lut, 
        output allocate,
        output out_sel
    );
endinterface

`endif //ROUTE_COMPUTE_VH
