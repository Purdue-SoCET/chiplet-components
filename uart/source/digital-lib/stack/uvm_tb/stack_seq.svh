import uvm_pkg::*;
`include "uvm_macros.svh"
`include "stack_transaction.svh"

class stack_seq #(type T = logic [7:0], parameter DEPTH = 8)extends uvm_sequence #(transaction);
    `uvm_object_utils(stack_seq)
    function new (string name = "");
        super.new(name);
    endfunction

    task body();
        transaction req_item;
        req_item = transaction#(T, DEPTH)::type_id::create("req_item");

        repeat(8) begin
        start_item(req_item);
        if(!req_item.randomize()) begin
            `uvm_fatal("stack_seq", "not able to randomize")
        end
        finish_item(req_item);
        end
        //`uvm_info(get_type_name(), $sformatf("[sequence] Sequencer running"), UVM_LOW)
        start_item(req_item);
        req_item.wdata = 0;
        req_item.push = 0;
        req_item.pop = 0;
        req_item.clear = 0;
        req_item.nRST = 0;
        finish_item(req_item);

        /*start_item(req_item);
        req_item.wdata = 0;
        req_item.push = 0;
        req_item.pop = 0;
        req_item.clear = 0;
        req_item.nRST = 1;
        finish_item(req_item);
                
        start_item(req_item);
        req_item.wdata = 0;
        req_item.push = 0;
        req_item.pop = 0;
        req_item.clear = 0;
        finish_item(req_item);

        start_item(req_item);
        req_item.wdata = 10;
        req_item.push = 1;
        req_item.pop = 0;
        req_item.clear = 0;
        finish_item(req_item);

        start_item(req_item);
        req_item.wdata = 68;
        req_item.push = 1;
        req_item.pop = 0;
        req_item.clear = 0;
        finish_item(req_item);

        start_item(req_item);
        req_item.wdata = 0;
        req_item.push = 0;
        req_item.pop = 1;
        req_item.clear = 0;
        `uvm_info(get_type_name(), $sformatf("req_item.wdata:%d", req_item.wdata), UVM_LOW)
        finish_item(req_item);*/

        // must have dummy transaction
        start_item(req_item);
        req_item.wdata = 0;
        req_item.push = 0;
        req_item.pop = 0;
        req_item.clear = 0;
        finish_item(req_item);
    endtask
endclass

class stack_sequencer#(type T = logic [7:0], int DEPTH = 8) extends uvm_sequencer#(transaction);
    `uvm_component_utils(stack_sequencer)
    function new(string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()
endclass