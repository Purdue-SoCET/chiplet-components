import uvm_pkg::*;
`include "uvm_macros.svh"
`include "agent.svh"
`include "counter_if.svh"
`include "scoreboard.svh"
`include "predictor.svh"
`include "transaction.svh"

class environment extends uvm_env;
    `uvm_component_utils(environment)

    agent agt; // monitor + driver
    predictor pred; // reference for result checking
    scoreboard scb; // scoreboard

    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        agt = agent::type_id::create("agt", this);
        pred = predictor::type_id::create("pred", this);
        scb = scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agt.mon.counter_ap.connect(pred.analysis_export); 
        pred.pred_ap.connect(scb.expected_export);
        agt.mon.result_ap.connect(scb.actual_export);
    endfunction

endclass: environment