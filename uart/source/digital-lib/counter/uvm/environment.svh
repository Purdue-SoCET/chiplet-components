import uvm_pkg::*;
`include "uvm_macros.svh"
`include "agent.svh"
`include "counter_if.svh"
`include "comparator.svh"
`include "predictor.svh"
`include "transaction.svh"

class environment extends uvm_env;
    `uvm_component_utils(environment)

    agent agt; // monitor + driver
    predictor pred; // reference for result checking
    comparator comp; // scoreboard

    function new(string name = "env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        agt = agent::type_id::create("agt", this);
        pred = predictor::type_id::create("pred", this);
        comp = comparator::type_id::create("comp", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        agt.mon.counter_ap.connect(pred.analysis_export); // monitor to predictor connection
        pred.pred_ap.connect(comp.expected_export); // predictor to comparator connection
        agt.mon.result_ap.connect(comp.actual_export); // monitor to comparator connection
    endfunction

endclass
