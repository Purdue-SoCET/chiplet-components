`ifndef WRAP_DEC_8B_10B_VH
`define WRAP_DEC_8B_10B_VH

`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"
interface wrap_dec_8b_10b_if;
    parameter PORTCOUNT = 5;
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

    logic done, done_out, err ,err_out;
    comma_length_sel_t comma_length_sel;
    flit_enc_t enc_flit;
    comma_sel_t comma_sel; 
    flit_t flit;

    //TODO 
    modport dec(
        input  enc_flit, done, comma_length_sel, err,
        output flit,comma_sel,done_out,err_out
    );

    modport switch(
        output enc_flit, done, comma_length_sel, err,
        input  flit,comma_sel,done_out,err_out
    );
endinterface

`endif // WRAP_DEC_8B_10B_VH
