`ifndef BUFFERS_VH
`define BUFFERS_VH

`include "chiplet_types_pkg.vh"

interface buffers_if #(
    parameter int NUM_BUFFERS, /* Assumed to be the same across links */
    parameter int NUM_OUTPORTS,
    parameter int NUM_VCS,
    parameter int DEPTH
);
    import chiplet_types_pkg::*;

    flit_t [NUM_BUFFERS-1:0] wdata, rdata;
    logic [NUM_BUFFERS-1:0] WEN, REN;
    logic [NUM_BUFFERS-1:0] req_routing, req_vc, req_switch, req_crossbar;
    // TODO: can make this a struct of {valid, clog2(sel)} to save some registers
    logic [NUM_BUFFERS-1:0] routing_granted, vc_granted, switch_granted;
    logic [$clog2(NUM_OUTPORTS)-1:0] routing_outport;
    logic [NUM_BUFFERS-1:0] [$clog2(NUM_OUTPORTS)-1:0] switch_outport;
    logic [$clog2(NUM_VCS)-1:0] vc_selection;
    logic [NUM_BUFFERS-1:0] final_vc;

    modport buffs(
        input wdata, WEN, REN, routing_granted, routing_outport, vc_granted, vc_selection, switch_granted,
        output rdata, req_routing, req_vc, switch_outport, req_switch, req_crossbar, final_vc
    );
endinterface

`endif //SWITCH_VH
