import uvm_pkg::*;
`include "uvm_macros.svh"
`include "stack_seq.svh"
`include "stack_driver.svh"
`include "stack_monitor.svh"

class stack_agent #(type T = logic [7:0], parameter DEPTH = 8) extends uvm_agent;
    `uvm_component_utils(stack_agent)
    stack_sequencer sqr;
    stack_driver drv;
    stack_monitor mon;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        sqr = stack_sequencer#(T, DEPTH)::type_id::create("sqr", this);
        drv = stack_driver#(T, DEPTH)::type_id::create("drv", this);
        mon = stack_monitor#(T, DEPTH)::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);  
    endfunction
endclass