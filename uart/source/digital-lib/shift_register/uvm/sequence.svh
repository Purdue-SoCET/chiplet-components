import uvm_pkg::*;
`include "uvm_macros.svh"
`include "transaction.svh"

class sr_sequence extends uvm_sequence #(transaction);
    `uvm_object_utils(sr_sequence)
    
    function new(string name = "");
        super.new(name);
    endfunction: new

    int num = 8;

    task body();
        transaction req_item;

        repeat(num) begin
            req_item = transaction#(4)::type_id::create("req_item");
            start_item(req_item);
            if (!req_item.randomize()) begin
                `uvm_fatal("sequence", "not able to memorize")
            end
            `uvm_info("SEQ", $sformatf("Generate new item %s", req_item.convert2str()), UVM_HIGH)
            finish_item(req_item);
        end
            `uvm_info("SEQ", $sformatf("Done generation of %d items", num), UVM_LOW)
    endtask: body

endclass

class sequencer extends uvm_sequencer#(transaction);
    `uvm_object_utils(sequencer)

    function new(string name = "sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction: new
endclass: sequencer
