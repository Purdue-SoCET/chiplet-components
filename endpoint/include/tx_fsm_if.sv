`ifndef TX_IF_SV
`define TX_IF_SV

`include "chiplet_types_pkg.vh"

interface tx_fsm_if #(
    parameter NUM_MSGS=4,
    parameter ADDR_WIDTH
);
    import chiplet_types_pkg::*;

    logic wen, start, busy, sending;
    logic [31:0] wdata;
    node_id_t node_id;

    modport tx_fsm(
        input wen, start, wdata, node_id,
        output busy, sending
    );
endinterface

`endif
