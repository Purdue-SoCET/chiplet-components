import uvm_pkg::*;
`include "uvm_macros.svh"
`include "transaction.svh"

class predictor extends uvm_subscriber #(transaction);
    `uvm_component_utils(predictor)
    
    uvm_analysis_port #(transaction) pred_ap;
    transaction output_tx;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        pred_ap = new("pred_ap", this);
    endfunction

    function void write (transaction t)
        // t is transaction sent from monitor
        output_tx = transaction#(4)::type_id::create("output_tx", this);
        output_tx.copy(t);
    endfunction




endclass: predictor
