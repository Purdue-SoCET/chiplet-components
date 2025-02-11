`ifndef PIPELINE_IF_SV
`define PIPELINE_IF_SV

`include "chiplet_types_pkg.vh"
`include "switch_pkg.sv"

interface pipeline_if #(
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS,
    parameter NUM_VCS
);
    import chiplet_types_pkg::*;
    import switch_pkg::*;

    localparam INGRESS_SIZE = $clog2(NUM_BUFFERS) + (NUM_BUFFERS == 1);
    localparam EGRESS_SIZE = $clog2(NUM_OUTPORTS) + (NUM_OUTPORTS == 1);

    // Route compute inputs
    logic rc_valid;
    flit_metadata_t rc_metadata;
    node_id_t rc_dest;
    logic [INGRESS_SIZE-1:0] rc_ingress_port;

    // VC allocator inputs
    logic vc_valid;
    flit_metadata_t vc_metadata;
    logic [INGRESS_SIZE-1:0] vc_ingress_port;
    logic [EGRESS_SIZE-1:0] vc_egress_port;

    // Switch allocator inputs
    logic sa_valid;
    logic [INGRESS_SIZE-1:0] sa_ingress_port;
    logic [EGRESS_SIZE-1:0] sa_egress_port;
    logic [$clog2(NUM_VCS)-1:0] sa_final_vc;

    // Switch allocator outputs
    logic pipe_valid;
    logic [INGRESS_SIZE-1:0] pipe_ingress_port;
    logic pipe_failed;

    modport rc(
        input rc_valid, rc_metadata, rc_dest, rc_ingress_port,
        output vc_valid, vc_metadata, vc_ingress_port, vc_egress_port
    );

    modport vc(
        input vc_valid, vc_metadata, vc_ingress_port, vc_egress_port,
        output sa_valid, sa_ingress_port, sa_egress_port, sa_final_vc
    );

    modport sa(
        input sa_valid, sa_ingress_port, sa_egress_port, sa_final_vc,
        output pipe_valid, pipe_ingress_port, pipe_failed
    );
endinterface

`endif //ROUTE_COMPUTE_VH
