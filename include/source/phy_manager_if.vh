
`ifndef PHY_MANAGER_VH
`define PHY_MANAGER_VH

`include "chiplet_types_pkg.vh"

interface phy_manager_if;
    import chiplet_types_pkg::*;

    logic data_ready, buffer_full;

    flit_t flit;

    logic [49:0] encoded_flit;

    modport rx_switch (
        input buffer_full,
        output data_ready,
        output flit
    );

    modport rx_phy (
        input encoded_flit,
        input data_ready,
        output buffer_full
    );

    modport tx_switch (
        input flit,
        input data_ready,
        output buffer_full
    );

    modport tx_phy (
        input buffer_full,
        output data_ready,
        output encoded_flit
    );

endinterface

`endif //PHY_MANAGER_VH
