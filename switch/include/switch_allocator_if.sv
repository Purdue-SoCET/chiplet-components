`ifndef SWITCH_ALLOCATOR_IF_SV
`define SWITCH_ALLOCATOR_IF_SV

interface switch_allocator_if #(
    parameter int NUM_BUFFERS,
    parameter int NUM_OUTPORTS
);
    // Request from each input buffer to allocate them to an output port
    logic [NUM_BUFFERS-1:0] allocate;
    // The requested output port from each input buffer
    logic [NUM_BUFFERS-1:0] [$clog2(NUM_OUTPORTS)-1:0] requested;
    // Input buffer select lines for each output port
    logic [NUM_OUTPORTS-1:0] [$clog2(NUM_BUFFERS)-1:0] select;
    logic [NUM_OUTPORTS-1:0] enable;

    modport route_compute(
        output allocate, requested
    );

    modport allocator(
        input allocate, requested,
        output select, enable
    );

    modport crossbar(
        input select, enable
    );
endinterface

`endif
