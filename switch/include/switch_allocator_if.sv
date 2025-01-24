`ifndef SWITCH_ALLOCATOR_IF_SV
`define SWITCH_ALLOCATOR_IF_SV

`include "switch_pkg.sv"

interface switch_allocator_if #(
    parameter int NUM_BUFFERS,
    parameter int NUM_OUTPORTS,
    parameter int NUM_VCS
);
    import switch_pkg::*;

    localparam REQUEST_SIZE = $clog2(NUM_OUTPORTS) + (NUM_OUTPORTS == 1);
    localparam SELECT_SIZE = $clog2(NUM_BUFFERS) + (NUM_BUFFERS == 1);

    // Used to tell when an outport can be deallocated
    logic [NUM_BUFFERS-1:0] valid;
    // Request from the input buffer to allocate them to an output port
    logic allocate;
    logic [SELECT_SIZE-1:0] requestor;
    // The requested output port from each input buffer
    logic [REQUEST_SIZE-1:0] requested;
    // The requested output vc from each input buffer
    logic [$clog2(NUM_VCS)-1:0] requested_vc;
    // Whether the switch was able to be allocated
    logic [SELECT_SIZE-1:0] switch_valid;
    // Input buffer select lines for each output port
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] [SELECT_SIZE-1:0] select;
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] enable;

    modport allocator(
        input valid, allocate, requestor, requested, requested_vc,
        output switch_valid, select, enable
    );

    modport crossbar(
        input select, enable
    );
endinterface

`endif
