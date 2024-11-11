`ifndef ROUTE_COMPUTE_VH
`define ROUTE_COMPUTE_VH

`include "chiplet_types_pkg.vh"

interface route_compute_if;

    import chiplet_types_pkg::*;

    flit_t [buffers-1:0] in_flit;


    //TODO 
    modport route(
        input in_flit,
        output 
    );
endinterface

`endif //ROUTE_COMPUTE_VH