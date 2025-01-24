`ifndef UART_TX_VH
`define UART_TX_VH

`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
interface uart_tx_if;
    import phy_types_pkg::*;
    parameter PORTCOUNT = 5;

    logic start;
    comma_length_sel_t comma_sel;
    flit_enc_t data;
    logic done, tx_err;
    logic [(PORTCOUNT -1):0] uart_out;
    //TODO 
    modport tx(
        input data, comma_sel, start,
        output uart_out,done, tx_err
    );
endinterface

`endif //ROUTE_COMPUTE_VH