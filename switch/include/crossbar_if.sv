`ifndef CROSSBAR_IF_SV
`define CROSSBAR_IF_SV

`include "switch_pkg.sv"

interface crossbar_if #(
    parameter type T,
    parameter int NUM_IN,
    parameter int NUM_OUT
);
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_IN) + (NUM_IN == 1);

    // Values to be muxed in
    T [NUM_IN-1:0] in;
    // Select lines for each output
    logic [NUM_OUT-1:0] [SELECT_SIZE-1:0] sel;
    // Output lines
    T [NUM_OUT-1:0] out;
    // Enables the output
    logic [NUM_OUT-1:0] enable;

    modport crossbar(
        input in, sel, enable,
        output out
    );

    modport switch(
        output in, sel
    );
endinterface

`endif
