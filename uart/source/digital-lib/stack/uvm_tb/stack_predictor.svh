import uvm_pkg::*;
`include "uvm_macros.svh"
`include "stack_transaction.svh"

class stack_predictor #(type T = logic [7:0], parameter DEPTH = 8) extends uvm_subscriber#(transaction);
    `uvm_component_utils(stack_predictor);

    uvm_analysis_port#(transaction) pred_ap;
    transaction pred_tx;
    T pred_stack [$:DEPTH-1];
    int size;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        pred_ap = new("pred_ap", this);
    endfunction

    function void write (transaction t);
        pred_tx = transaction#(T, DEPTH)::type_id::create("pred_tx", this);
        pred_tx.copy(t);
        `uvm_info(get_type_name(), $sformatf("pred_tx.wdata:%d",pred_tx.wdata), UVM_LOW)
        size = pred_stack.size();
        if (t.push) begin
            if (size == DEPTH)begin
                pred_tx.overflow = 1;
            end else begin 
                pred_tx.overflow = 0;
                pred_stack.push_back(t.wdata); 
            end
        end

        //rdata shows the last element regardless of pop.
        pred_tx.rdata = pred_stack[$];

        size = pred_stack.size();
        `uvm_info(get_type_name(), $sformatf("t.pop:%d \n", t.pop), UVM_LOW)

        if (t.pop) begin
            if (size == 0) begin
                pred_tx.underflow = 1;
            end else begin
                `uvm_info(get_type_name(), $sformatf("stack count:%d \n", pred_stack.size()), UVM_LOW)
                pred_tx.underflow = 0;
                pred_stack.pop_back();
                pred_tx.rdata = pred_stack[$];
            end
        end
        
        size = pred_stack.size();
        pred_tx.count = size;

        if (size >= DEPTH) begin
            pred_tx.full = 1;
            if (size > DEPTH) begin
                pred_tx.rdata = 0;
                `uvm_info(get_type_name(), $sformatf("Full stack, undefined rdata\n"), UVM_LOW)
            end end else begin
            pred_tx.full = 0;
        end

        if (size == 0) begin
            pred_tx.empty = 1;
            pred_tx.rdata = 0;
            `uvm_info(get_type_name(), $sformatf("Empty stack, undefined rdata\n"), UVM_LOW)
        end else begin
            pred_tx.empty = 0;
        end

        if (t.clear || !t.nRST)begin
            pred_tx.rdata = 0;
            pred_tx.count = 0;
            pred_tx.empty = 1;
            pred_tx.full = 0;
            pred_tx.overflow = 0;
            pred_tx.underflow = 0;
            pred_stack = {};
            `uvm_info(get_type_name(), $sformatf("Reset/Clear initiated. Count:%d, rdata:%d\n", pred_tx.count, pred_tx.rdata), UVM_LOW)
        end
        pred_ap.write(pred_tx);
    endfunction
endclass