`ifndef SWITCH_VH
`define SWITCH_VH

`include "chiplet_types_pkg.vh"

interface switch_if #(
    parameter buffers
);

    import chiplet_types_pkg::*;

    flit_t [buffers-1:0] in_flit, out_flit;


    //TODO 
    modport switch(
        input in_flit,
        output out_flit
    );
endinterface

`endif //SWITCH_VH