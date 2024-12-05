`ifndef WRAP_DEC_8B_10B_VH
`define WRAP_DEC_8B_10B_VH

`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
interface arb_que_if;
    parameter NBITS = 8;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    logic en,dec;
    logic clear;
    logic [3:0] count_in;
    logic[NBITS - 1:0] que_out,que_in;
    //TODO 
    modport que(
        input en, clear, dec, que_in,count_in,
        output que_out
    );
endinterface

`endif //ROUTE_COMPUTE_VH