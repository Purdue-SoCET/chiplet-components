`define CROSSBAR_IF_SV

interface crossbar_if #(
    parameter type T,
    parameter T RESET_VAL,
    parameter int M,
    parameter int N
);
    T [M-1:0] in;
    logic [$clog2(N)-1:0] sel;
    T [N-1:0] out;

    modport crossbar(
        input in, sel, enable,
        output out
    );

    modport switch(
        output in, sel
    );
endinterface

`endif
