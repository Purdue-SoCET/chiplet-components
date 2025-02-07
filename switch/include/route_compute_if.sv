`ifndef ROUTE_COMPUTE_VH
`define ROUTE_COMPUTE_VH

`include "chiplet_types_pkg.vh"
`include "switch_pkg.sv"

interface route_compute_if #(
    parameter NUM_OUTPORTS,
    parameter TABLE_SIZE
);
    import chiplet_types_pkg::*;
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_OUTPORTS) + (NUM_OUTPORTS == 1);

    logic valid;
    flit_t head_flit;
    route_lut_entry_t [TABLE_SIZE-1:0] route_lut;
    logic [SELECT_SIZE-1:0] out_sel;
    logic [NUM_OUTPORTS-1:0] buffer_available;

    //TODO 
    modport route(
        input valid, head_flit, route_lut, buffer_available,
        output out_sel
    );
endinterface

`endif //ROUTE_COMPUTE_VH
