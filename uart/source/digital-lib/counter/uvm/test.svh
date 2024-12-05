import uvm_pkg::*;
`include "uvm_macros.svh"
`include "environment.svh"

class test extends uvm_test;
`uvm_component_utils(test)

environment env; // top level environment
virtual counter_if vif;
counter_sequence seq; // single sequencing test

function new(string name = "test", uvm_component parent);
    super.new(name, parent);
endfunction: new

function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = environment::type_id::create("env", this);
    seq = counter_sequence::type_id::create("seq");

    if (!uvm_config_db#(virtual counter_if)::get(this, "", "counter_vif", vif)) begin
        // check for correct interface in database
        `uvm_fatal("TEST", "No virtual interface specified for this test instance")
    end
endfunction: build_phase

task run_phase(uvm_phase phase);
    phase.raise_objection(this, "Starting sequence in main phase");
    $display("%t Starting sequence run_phase", $time);
    seq.start(env.agt.sqr);
    #100ns;
    phase.drop_objection(this, "Finished in main phase");
endtask

endclass
