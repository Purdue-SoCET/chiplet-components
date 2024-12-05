//Help

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "transaction.svh"

class counter_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(ctr_sequence)
    
    function new(string name = "ctr_sequence");
        super.new(name);
    endfunction: new


    task body();
        transaction req_item;
        req_item = transaction#(4)::type_id::create("req_item");
        repeat(20) begin
            start_item(req_item);
            if (!req_item.randomize()) begin
                `uvm_fatal("sequence", "not able to memorize")
            end
            finish_item(req_item);
        end
    endtask: body

endclass

class sequencer extends uvm_sequencer#(transaction);
    `uvm_object_utils(sequencer)

    function new(string name = "sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction: new
endclass: sequencer