`ifndef SWITCH_PKG_SV
`define SWITCH_PKG_SV
`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"

package switch_pkg;
    import chiplet_types_pkg::*;

    // TODO: make a version with static out_sel size since the routing table
    // depends on this
    typedef struct packed {
        node_id_t   req;
        node_id_t   dest;
        logic [4:0] out_sel;
    } route_lut_t;
endpackage
`endif //CHIPLET_TYPES_PKG_VH
