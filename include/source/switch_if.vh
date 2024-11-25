`ifndef SWITCH_VH
`define SWITCH_VH

`include "chiplet_types_pkg.vh"

interface switch_if #(
    parameter int NUM_OUTPORTS,
    parameter int NUM_BUFFERS, /* Assumed to be the same across links */
    parameter int NUM_VCS /* Assumed to be the same across links */
);

    import chiplet_types_pkg::*;

    flit_t [NUM_BUFFERS-1:0] in; 
    logic [NUM_BUFFERS-1:0] data_ready_in;
    flit_t [NUM_OUTPORTS-1:0] out;
    logic [NUM_OUTPORTS-1:0] data_ready_out;
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] buffer_available;
    logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] credit_granted;
    //logic [NUM_BUFFERS-1:0] buffer_full;

    //TODO 
    modport switch(
        input in_flit, credit_granted, data_ready_in,
        output out_flit, buffer_available, data_ready_out
    );
endinterface

`endif //SWITCH_VH