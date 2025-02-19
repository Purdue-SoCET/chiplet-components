import uvm_pkg::*;
`include "uvm_macros.svh"
`include "environment.svh"

class test extends uvm_test; //Declare new class that derives from "uvm_test"
    `uvm_component_utils(test) //Register classs with UVM Factory

    //Declare testbench components
    environment env; // testbench environment
    virtual sr_if vif;
    sr_sequence seq;

    function new(string name = "test", uvm_component parent); //Define "new" function
        super.new(name, parent);
    endfunction



    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = environment::type_id::create("env", this);
        seq = sr_sequence::type_id::create("seq");

        if (!uvm_config_db#(virtual sr_if)::get(this, "", "sr_if", vif)) begin 
		   `uvm_fatal("TEST", "No virtual interface specified for this test instance")
		end 
		//uvm_config_db#(virtual sr_if)::set(this, "env.agt*", "sr_vif", vif);

        seq.randomize();
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        seq.start(env.agt.sqr);
        #200;
        phase.drop_objection(this);
    endtask

    endclass

class testnum1 extends test;
    `uvm_component_utils(testnum1)
    function new(string name = "testnum1", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass


