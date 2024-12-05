`ifndef ENVIRONMENT_SVH
`define ENVIRONMENT_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_agent.svh"
`include "fifo_if.svh"
`include "scoreboard.svh"
`include "predictor.svh"
`include "coverage.svh"
`include "fifo_transaction.svh"
`include "clk_agent.svh"
`include "clk_transaction.svh"

class environment #(type T = logic [7:0], int DEPTH = 8) extends uvm_env;
    `uvm_component_utils(environment#(T, DEPTH))
    fifo_agent#(T, DEPTH) fifo_agt;
    predictor#(T, DEPTH) pred;
    coverage#(T, DEPTH) cov;
    scoreboard#(T, DEPTH) scrb;
    clk_agent#(T, DEPTH) clk_agt;
    
    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        fifo_agt = fifo_agent#(T, DEPTH)::type_id::create("fifo_agt", this);
        pred = predictor#(T, DEPTH)::type_id::create("pred", this);
        cov = coverage#(T, DEPTH)::type_id::create("cov", this);
        scrb = scoreboard#(T, DEPTH)::type_id::create("scrb", this);
        clk_agt = clk_agent#(T, DEPTH)::type_id::create("clk_agt", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        fifo_agt.mon.fifo_ap.connect(pred.analysis_export);
        pred.pred_ap.connect(scrb.expected_export);
        fifo_agt.mon.result_ap.connect(scrb.actual_export);

        fifo_agt.mon.fifo_ap.connect(cov.analysis_imp_inp);
        fifo_agt.mon.result_ap.connect(cov.analysis_imp_outp);
    endfunction
endclass: environment //environment extends uvm_env

`endif
