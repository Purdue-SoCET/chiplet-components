`ifndef CROSSBAR_IF_SV
`define CROSSBAR_IF_SV

`include "switch_pkg.sv"

interface crossbar_if #(
    parameter int NUM_IN,
    parameter int NUM_OUT,
    parameter int NUM_VCS
);
    import switch_pkg::*;

    localparam SELECT_SIZE = $clog2(NUM_IN) + (NUM_IN == 1);

    logic [NUM_OUT-1:0] packet_sent;
    // Values to be muxed in
    flit_t [NUM_IN-1:0] in;
    logic [NUM_IN-1:0] empty;
    // Select lines for each output
    logic [NUM_OUT-1:0] [NUM_VCS-1:0] [SELECT_SIZE-1:0] sel;
    // Output lines
    flit_t [NUM_OUT-1:0] out;
    logic [NUM_OUT-1:0] valid;
    // Enables the output
    logic [NUM_OUT-1:0] [NUM_VCS-1:0] enable;
    // Tells each input when the packet has been sent
    logic [NUM_IN-1:0] in_pop;
    // Grant credit to each outport
    logic [NUM_OUT-1:0] [NUM_VCS-1:0] credit_granted;

    modport crossbar(
        input in, empty, sel, enable, packet_sent, credit_granted,
        output out, in_pop, valid
    );

    modport switch(
        output in, sel
    );
endinterface

`endif
