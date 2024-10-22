`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"

module rx_phy_manager #() (
    input logic clk, n_rst,
    phy_manager_if.rx_switch switch_if
    phy_manager_if.rx_phy phy_if
);

    import chiplet_types_pkg::*;

    flit_t flit;
    logic [39:0] decode_output;

    always_comb begin //8b10b decode



        flit = flit_t'(decode_output);
    end

    always_comb begin //CRC checker


    end

    always_comb begin //format check


    end


endmodule