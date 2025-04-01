`ifndef TX_IF_SV
`define TX_IF_SV

`include "chiplet_types_pkg.vh"

interface tx_fsm_if #(
    parameter NUM_MSGS=4,
    parameter ADDR_WIDTH
);
    import chiplet_types_pkg::*;

    logic fifo_ren;
    logic [31:0] fifo_rdata;
    node_id_t node_id;

    modport tx_fsm(
        input fifo_rdata, node_id,
        output fifo_ren
    );
endinterface

`endif
