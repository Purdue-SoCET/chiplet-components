`ifndef ENDPOINT_IF_SV
`define ENDPOINT_IF_SV

`include "chiplet_types_pkg.vh"

interface endpoint_if #(
    parameter NUM_VCS=2
) (
    switch_if switch_if
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

    assign endpoint_if.out = sw_if.out[0];
    assign endpoint_if.buffer_available = sw_if.buffer_available[0];
    assign endpoint_if.data_ready_out = sw_if.data_ready_out[0];
    assign endpoint_if.node_id = sw_if.node_id;
    assign sw_if.in[0] = endpoint_if.in;
    assign sw_if.credit_granted[0] = endpoint_if.credit_granted;
    assign sw_if.data_ready_in[0] = endpoint_if.data_ready_in;
    assign sw_if.packet_sent[0] = endpoint_if.packet_sent;

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
