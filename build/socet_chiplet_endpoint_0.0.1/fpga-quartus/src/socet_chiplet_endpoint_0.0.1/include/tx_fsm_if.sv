`ifndef TX_IF_SV
`define TX_IF_SV

`include "chiplet_types_pkg.vh"

interface tx_fsm_if #(
    parameter NUM_MSGS=4,
    parameter ADDR_WIDTH
);
    import chiplet_types_pkg::*;

    logic [NUM_MSGS-1:0] [ADDR_WIDTH-1:0] pkt_start_addr;
    node_id_t node_id;

    modport tx_fsm(
        input pkt_start_addr, node_id
    );
endinterface

`endif
