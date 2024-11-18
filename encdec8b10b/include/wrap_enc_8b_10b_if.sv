`ifndef ENC_8B_10B_WRAP_VH
`define ENC_8B_10B_WRAP_VH

`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
interface wrap_enc_8b_10b_if;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

    logic start, start_out;
    comma_sel_t comma_sel; 
    flit_t flit;
    flit_enc_t flit_out;
    comma_length_sel_t comma_length_sel_out;

    //TODO 
    modport enc(
        input  start, flit, comma_sel,
        output flit_out, comma_length_sel_out, start_out
    );

    modport switch(
        output start, flit, comma_sel,
        input  flit_out, comma_length_sel_out, start_out
    );
endinterface

`endif //ROUTE_COMPUTE_VH
