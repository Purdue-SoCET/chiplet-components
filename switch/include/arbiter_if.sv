`ifndef ARBITER_IF_VH
`define ARBITER_IF_VH

`include "chiplet_types_pkg.vh"

interface arbiter_if #(
    parameter int WIDTH
);
    import chiplet_types_pkg::*;

    logic [WIDTH-1:0] bid;
    logic valid;
    logic [$clog2(WIDTH)-1:0] select;

    modport arbiter(
        input bid,
        output valid, select
    );
endinterface

`endif //SWITCH_VH
