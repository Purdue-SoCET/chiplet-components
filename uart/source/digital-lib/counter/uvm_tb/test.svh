import uvm_pkg::*;
`include "uvm_macros.svh"
`include "environment.svh"

class test extends uvm_test;
    `uvm_component_utils(test)
    
    function new(string name = "test", uvm_component parent = null);
        super.new(name, parent);
    endfunction: new

    environment env; // top level environment

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = environment::type_id::create("env", this);

    endfunction: build_phase

    task run_phase(uvm_phase phase);
        ctr_sequence seq = ctr_sequence::type_id::create("seq");
        super.run_phase(phrase);
        phase.raise_objection(this);
        seq.start(env.sqr);
        phase.drop_objection(this);
    endtask

endclass: test