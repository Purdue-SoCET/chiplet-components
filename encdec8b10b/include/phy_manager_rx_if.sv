`ifndef PHY_MANAGER_RX_IF
`define PHY_MANAGER_RX_IF

`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
interface phy_manager_rx_if #(
    parameter PORTCOUNT = 5
);
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

    logic crc_corr, done_uart_rx, done_out, uart_err_rx ,err_out, packet_done;
    comma_length_sel_t comma_length_sel_rx;
    flit_enc_t enc_flit_rx;
    comma_sel_t comma_sel;
    flit_t flit;

    //TODO
    modport mng_rx(
        input enc_flit_rx, done_uart_rx, comma_length_sel_rx, uart_err_rx,
        output flit,comma_sel,done_out,err_out,crc_corr, packet_done
    );
endinterface

`endif //ROUTE_COMPUTE_VH
