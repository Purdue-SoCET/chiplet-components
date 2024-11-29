`ifndef CROSSBAR_IF_SV
`define CROSSBAR_IF_SV

interface crossbar_if #(
    parameter type T,
    parameter int NUM_IN,
    parameter int NUM_OUT
);
    // Values to be muxed in
    T [NUM_IN-1:0] in;
    // Select lines for each output
    logic [NUM_OUT-1:0] [$clog2(NUM_IN)-1:0] sel;
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
