`ifndef ENDPOINT_IF_SV
`define ENDPOINT_IF_SV

`include "chiplet_types_pkg.vh"

interface endpoint_if #(
    parameter NUM_VCS=2
);
    import chiplet_types_pkg::*;

    flit_t in;
    logic data_ready_in;
    flit_t out;
    logic data_ready_out;
    logic [NUM_VCS-1:0] buffer_available;
    logic [NUM_VCS-1:0] credit_granted;
    logic packet_sent;
    node_id_t node_id;

    modport endpoint(
        input out, buffer_available, data_ready_out, node_id,
        output in, credit_granted, data_ready_in, packet_sent
    );

    modport rx_fsm(
        input out, buffer_available, data_ready_out,
        output credit_granted, packet_sent
    );

    modport tx_fsm(
        input node_id, buffer_available,
        output in, data_ready_in
    );
endinterface

`endif //ENDPOINT_IF_SV
