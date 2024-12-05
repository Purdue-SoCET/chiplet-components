`ifndef WRAP_DEC_8B_10B_VH
`define WRAP_DEC_8B_10B_VH

`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
interface arb_counter_if;
    parameter NBITS = 4;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    logic en,dec;
    logic clear;
    logic overflow;
    logic[NBITS - 1:0] count;
    //TODO 
    modport cnt(
        input en, clear, dec,
        output count
    );
endinterface

`endif //ROUTE_COMPUTE_VH