`ifndef SWITCH_PKG_SV
`define SWITCH_PKG_SV
`timescale 1ns / 10ps
package switch_pkg;
    parameter NUM_OUTPORTS = 2;

    // TODO: make a version with static out_sel size since the routing table
    // depends on this
    typedef struct packed {
        node_id_t   req;
        node_id_t   dest;
        logic [4:0] out_sel;
    } route_lut_t;
endpackage
`endif //CHIPLET_TYPES_PKG_VH
