`ifndef RX_IF_SV
`define RX_IF_SV

`include "chiplet_types_pkg.vh"

interface rx_fsm_if;
    import chiplet_types_pkg::*;

    logic metadata_full, metadata_fifo_wen, rx_fifo_full, rx_fifo_wen;
    logic [6:0] metadata;

    modport rx_fsm(
        input metadata_full, rx_fifo_full,
        output metadata_fifo_wen, rx_fifo_wen, metadata
    );

    modport metadata_fifo(
        output metadata_full,
        input  metadata_fifo_wen, metadata
    );
endinterface

`endif
