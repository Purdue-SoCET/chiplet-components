`ifndef UART_RX_VH
`define UART_RX_VH

`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
interface uart_rx_if;
    parameter PORTCOUNT = 5;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;
    logic [(PORTCOUNT -1):0] uart_in;
    flit_enc_t data;
    comma_length_sel_t comma_sel;
    logic done, rx_err;
    //TODO 
    modport rx(
        input uart_in,
        output data,comma_sel,done,rx_err
    );
endinterface

`endif //ROUTE_COMPUTE_VH