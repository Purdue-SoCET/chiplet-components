`ifndef SWITCH_ALLOCATOR_IF_SV
`define SWITCH_ALLOCATOR_IF_SV

`include "switch_pkg.sv"

interface switch_allocator_if #(
    parameter int NUM_BUFFERS,
    parameter int NUM_OUTPORTS,
    parameter int NUM_VCS
);
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_BUFFERS) + (NUM_BUFFERS == 1);

    logic reg_bank_claim;
    // Used to tell when an outport can be deallocated
    logic [NUM_BUFFERS-1:0] valid;
    // Input buffer select lines for each output port
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] [SELECT_SIZE-1:0] select;
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] enable;

    modport allocator(
        input valid, reg_bank_claim,
        output select, enable
    );

    modport crossbar(
        input select, enable
    );
endinterface

`endif
