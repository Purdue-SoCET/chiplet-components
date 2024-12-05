import uvm_pkg::*;
`include "uvm_macros.svh"
`include "stack_agent.svh"
`include "stack_if.svh"
`include "stack_scoreboard.svh"
`include "stack_predictor.svh"
`include "stack_transaction.svh"

class environment#(type T = logic [7:0], parameter DEPTH = 8) extends uvm_env;
    `uvm_component_utils(environment)
    stack_agent stack_agt;
    stack_predictor stack_pred;
    scoreboard scrb;

    function new (string name = "environment", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        stack_agt = stack_agent#(T,DEPTH)::type_id::create("stack_agt", this);
        stack_pred = stack_predictor#(T,DEPTH)::type_id::create("stack_pred", this);
        scrb = scoreboard#(T,DEPTH)::type_id::create("scrb0", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        stack_agt.mon.stack_ap.connect(stack_pred.analysis_export);
        stack_pred.pred_ap.connect(scrb.expected_export);
        stack_agt.mon.result_ap.connect(scrb.actual_export);
    endfunction
endclass