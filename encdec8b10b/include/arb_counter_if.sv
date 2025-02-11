`ifndef ARB_COUNTER_IF
`define ARB_COUNTER_IF

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
        output count,overflow
    );
endinterface

`endif //ROUTE_COMPUTE_VH