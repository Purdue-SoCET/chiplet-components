`ifndef STACK_TRANSACTION_SVH
`define STACK_TRANSACTION_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

class transaction #(type T = logic [7:0],parameter DEPTH = 8) extends uvm_sequence_item;
    // list of inputs
    bit nRST = 1;
    rand bit push;
    rand bit pop;
    rand bit clear;
    rand T wdata;
    // list of outputs
    bit empty;
    bit full;
    bit overflow;
    bit underflow;
    bit [$clog2(DEPTH):0] count;
    T rdata;

    `uvm_object_utils_begin(transaction)
        `uvm_field_int(nRST, UVM_ALL_ON)
        `uvm_field_int(push, UVM_ALL_ON)
        `uvm_field_int(pop, UVM_ALL_ON)
        `uvm_field_int(clear, UVM_ALL_ON)
        `uvm_field_int(wdata, UVM_ALL_ON)
        `uvm_field_int(empty, UVM_ALL_ON)
        `uvm_field_int(full, UVM_ALL_ON)
        `uvm_field_int(overflow, UVM_ALL_ON)
        `uvm_field_int(underflow, UVM_ALL_ON)
        `uvm_field_int(count, UVM_ALL_ON)
        `uvm_field_int(rdata, UVM_ALL_ON)
    `uvm_object_utils_end

    //constraints
    constraint input_constr {
        //some constraints
        pop dist{0 := 15, 1 := 8};
        if (push == 1) pop == 0;
        if (push == 0) pop == 1;
        //if (pop == 1) push == 0;
        clear dist{ 0 := 10, 1 := 0 };
    }

    function new (string name = "stack_sequencer");
        super.new(name);
    endfunction: new

endclass: transaction
`endif