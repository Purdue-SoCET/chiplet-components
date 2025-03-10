`ifndef SWITCH_REG_BANK_VH
`define SWITCH_REG_BANK_VH

`include "chiplet_types_pkg.vh"
`include "switch_pkg.sv"

interface switch_reg_bank_if #(
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS,
    parameter TOTAL_NODES,
    parameter TABLE_SIZE
);
    import chiplet_types_pkg::*;
    import switch_pkg::*;

    logic reg_bank_claim;
    flit_t in_flit;
    logic [NUM_OUTPORTS-1:0] dateline;
    route_lut_t [TABLE_SIZE-1:0] route_lut;
    node_id_t node_id;


    modport reg_bank(
        input in_flit,
        output dateline, route_lut, node_id
    );

    modport rc(
        input route_lut, reg_bank_claim, node_id
    );

    modport vc(
        input dateline
    );
endinterface

`endif //SWITCH_REG_BANK_VH
