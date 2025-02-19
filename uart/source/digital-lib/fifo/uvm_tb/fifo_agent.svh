import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_seq.svh"
`include "fifo_driver.svh"
`include "fifo_monitor.svh"

class fifo_agent #(type T = logic [7:0], int DEPTH = 8) extends uvm_agent;
    `uvm_component_utils(fifo_agent#(T, DEPTH))
    fifo_sequencer#(T, DEPTH) sqr;
    fifo_driver#(T, DEPTH) drv;
    fifo_monitor#(T, DEPTH) mon;
    
    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        sqr = fifo_sequencer#(T, DEPTH)::type_id::create("sqr", this);
        drv = fifo_driver#(T, DEPTH)::type_id::create("drv", this);
        mon = fifo_monitor#(T, DEPTH)::type_id::create("mon", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass //fifo_agent extends uvm_agent
