import uvm_pkg::*;
`include "uvm_macros.svh"
`include "clk_seq.svh"
`include "clk_driver.svh"

class clk_agent#(type T = logic [7:0], int DEPTH = 8) extends uvm_agent;
    `uvm_component_utils(clk_agent#(T, DEPTH))
    clk_sequencer sqr;
    clk_driver#(T, DEPTH) drv;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        sqr = clk_sequencer::type_id::create("clk_sqr", this);
        drv = clk_driver#(T, DEPTH)::type_id::create("clk_drv", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
endclass //clk_agent extends uvm_agent
