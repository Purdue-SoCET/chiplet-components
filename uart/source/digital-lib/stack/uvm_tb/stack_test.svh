`ifndef STACK_TEST_SVH
`define STACK_TEST_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "stack_env.svh"

class stack_test extends uvm_test;
    `uvm_component_utils(stack_test)

    environment env;
    virtual stack_if vif;
    stack_seq seq;
    
    function new(string name = "stack_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase (uvm_phase phase);
        super.build_phase(phase);
        env = environment#()::type_id::create("env", this);
        seq = stack_seq#()::type_id::create("seq", this);
        
        if (!uvm_config_db#(virtual stack_if)::get(this, "", "stack_vif", vif)) begin 
            // check if interface is correctly set in testbench top level
		   `uvm_fatal("STACK TEST", "No virtual interface specified for this test instance")
		end 

		uvm_config_db#(virtual stack_if)::set(this, "env.agt*", "stack_vif", vif);
    endfunction

    task run_phase (uvm_phase phase);
        phase.raise_objection(this, "Starting run_phase");
        seq.start(env.stack_agt.sqr);
        phase.drop_objection(this, "Finished run phase");
    endtask
endclass: stack_test 

`endif  