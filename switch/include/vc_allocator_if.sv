`ifndef VC_ALLOCATOR_IF_SV
`define VC_ALLOCATOR_IF_SV

interface vc_allocator_if #(
    parameter int NUM_OUTPORTS,
    parameter int NUM_BUFFERS, /* Assumed to be the same across links */
    parameter int NUM_VCS /* Assumed to be the same across links */
);
    // Current VC of the packet
    logic [NUM_BUFFERS-1:0] [$clog2(NUM_VCS)-1:0] incoming_vc;
    // Final VC of the packet
    logic [NUM_BUFFERS-1:0] [$clog2(NUM_VCS)-1:0] assigned_vc;
    // Whether there is an available buffer across the link
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] buffer_available;
    // Packet sent across the link
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] packet_sent;
    // Credit granted across the link
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] credit_granted;
    // Dateline configuration
    logic [NUM_OUTPORTS-1:0] dateline;

    modport allocator(
        input incoming_vc, packet_sent, credit_granted, dateline,
        output assigned_vc, buffer_available
    );
endinterface

`endif