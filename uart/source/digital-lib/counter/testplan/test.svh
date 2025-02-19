import uvm_pkg::*;
'include "uvm_macros.svh"
'include "enviroment.svh"

class test extends uvm_test;
	'uvm_component_utils(test)
	
	//instantiate classes
	enviroment env;
		
	//constructor
	function new(string name = "test", uvm_component parent);
		super.new(name, parent);
	endfunction: new

	//build phase
	function void build_phase(uvm_phase phase);

		env = enviroment::type_id::create("env", this); //create new object
		
	endfunction: build_phase
	
	task run_phase(uvm_phase phase);
		
	endtask

endclass:test
