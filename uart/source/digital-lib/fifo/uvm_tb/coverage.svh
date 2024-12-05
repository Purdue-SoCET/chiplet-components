import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_transaction.svh"

`uvm_analysis_imp_decl(_port_inp)
`uvm_analysis_imp_decl(_port_outp)
class coverage #(type T = logic [7:0], int DEPTH = 8) extends uvm_subscriber#(transaction#(T, DEPTH));
    `uvm_component_utils(coverage#(T, DEPTH))

    uvm_analysis_imp_port_inp #(transaction#(T, DEPTH),coverage#(T, DEPTH)) analysis_imp_inp;
    uvm_analysis_imp_port_outp #(transaction#(T, DEPTH),coverage#(T, DEPTH)) analysis_imp_outp;
    uvm_analysis_port#(transaction#(T, DEPTH)) cov_ap;
    transaction#(T,DEPTH) txn;

    covergroup fifo_in;
        wdata_cp: coverpoint txn.wdata {
            bins zero = {0};
            bins posrange[16] = {[1:$]};
            bins negrange[16] = {[$:-1]};
        }
        wen_cp: coverpoint txn.WEN {
            bins zero = {0};
            bins one = {1};
        }
        cross_cp: cross wdata_cp, wen_cp;
    endgroup

    covergroup fifo_out;
        rdata_cp: coverpoint txn.rdata {
            bins zero = {0};
            bins posrange[16] = {[1:$]};
            bins negrange[16] = {[$:-1]};
        }
        count_cp: coverpoint txn.count {
            bins zero = {0};
            bins count_range[31] = {[1:$]};
        }
    endgroup

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        analysis_imp_inp = new("ap_inp", this);
        analysis_imp_outp = new("ap_outp", this);
        fifo_in = new();
        fifo_out = new();
    endfunction //new()

    function void build_phase(uvm_phase phase);
        cov_ap = new("cov_ap", this);
    endfunction

    function void write(transaction#(T, DEPTH) t);  // overwrites uvm_subscriber write()
        this.txn = t;
    endfunction

    virtual function void write_port_inp(transaction#(T, DEPTH) t);
        this.txn = t;
        fifo_in.sample();
    endfunction

    virtual function void write_port_outp(transaction#(T, DEPTH) t);
        this.txn = t;
        fifo_out.sample();
    endfunction
endclass //coverage extends uvm_subscriber
