`ifndef BUFFERS_VH
`define BUFFERS_VH

`include "chiplet_types_pkg.vh"

interface buffers_if #(
    parameter int NUM_BUFFERS, /* Assumed to be the same across links */
    parameter int NUM_OUTPORTS,
    parameter int NUM_VCS,
    parameter int DEPTH
);
    import chiplet_types_pkg::*;

    flit_t [NUM_BUFFERS-1:0] wdata, rdata;
    logic [NUM_BUFFERS-1:0] WEN, REN;
    logic [NUM_BUFFERS-1:0] req_pipeline, pipeline_failed, reg_bank_granted, pipeline_granted;
    logic [NUM_BUFFERS-1:0] active;
    logic [NUM_BUFFERS-1:0] available;
    logic [NUM_BUFFERS-1:0] empty;

    modport buffs(
        input wdata, WEN, REN, pipeline_failed, reg_bank_granted, pipeline_granted,
        output rdata, req_pipeline, active, available, empty
    );
endinterface

`endif //SWITCH_VH
