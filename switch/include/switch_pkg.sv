`ifndef SWITCH_PKG_SV
`define SWITCH_PKG_SV
`timescale 1ns / 10ps
package switch_pkg;
    parameter NUM_OUTPORTS = 2;

    typedef struct packed {
        logic [$clog2(NUM_OUTPORTS)-1:0] out_sel;
        node_id_t                   req;
        node_id_t                   dest;
    } route_lut_t;
endpackage
`endif //CHIPLET_TYPES_PKG_VH