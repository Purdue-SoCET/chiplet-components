`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

class transaction #(type T = logic [7:0], int DEPTH = 8) extends uvm_sequence_item;
    rand T wdata;
    rand bit WEN;
    rand bit REN;
    rand bit clear;
    bit nRST;  // only read

    bit full;
    bit empty;
    bit overrun;
    bit underrun;
    bit [$clog2(DEPTH) - 1:0] count;
    T rdata;

    `uvm_object_utils_begin(transaction#(T, DEPTH))
        `uvm_field_int(wdata, UVM_NOCOMPARE)
        `uvm_field_int(WEN, UVM_NOCOMPARE)
        `uvm_field_int(REN, UVM_NOCOMPARE)
        `uvm_field_int(clear, UVM_NOCOMPARE)
        `uvm_field_int(full, UVM_DEFAULT)
        `uvm_field_int(empty, UVM_DEFAULT)
        `uvm_field_int(overrun, UVM_DEFAULT)
        `uvm_field_int(underrun, UVM_DEFAULT)
        `uvm_field_int(count, UVM_DEFAULT)
        `uvm_field_int(rdata, UVM_DEFAULT)
    `uvm_object_utils_end

    // randomization constraints
    constraint tx_constr {
        // if (WEN == 1) REN == 0;
        // if (REN == 1) WEN == 0;
        clear dist{ 0 := 19, 1 := 1 };
    }

    function new(string name = "transaction");
        super.new(name);
    endfunction //new()

endclass //transaction extends uvm_sequence_item

`endif
