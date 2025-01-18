`ifndef VC_ALLOCATOR_IF_SV
`define VC_ALLOCATOR_IF_SV

interface vc_allocator_if #(
    parameter int NUM_OUTPORTS,
    parameter int NUM_VCS /* Assumed to be the same across links */
);
    // Current VC of the packet
    logic [$clog2(NUM_VCS)-1:0] incoming_vc;
    // Outport of the flit
    logic [$clog2(NUM_OUTPORTS)-1:0] outport;
    // Final VC of the packet
    logic [$clog2(NUM_VCS)-1:0] assigned_vc;
    // Dateline configuration
    logic [NUM_OUTPORTS-1:0] dateline;

    modport allocator(
        input incoming_vc, outport, dateline,
        output assigned_vc
    );
endinterface

`endif
