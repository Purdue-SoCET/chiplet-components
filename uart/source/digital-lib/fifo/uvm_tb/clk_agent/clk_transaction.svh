`ifndef CLK_TRANSACTION_SVH
`define CLK_TRANSACTION_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

class clk_transaction extends uvm_sequence_item;
    bit clk;
    rand bit nRST = 1;

    `uvm_object_utils_begin(clk_transaction)
        `uvm_field_int(clk, UVM_NOCOMPARE)
        `uvm_field_int(nRST, UVM_NOCOMPARE)
    `uvm_object_utils_end

    // randomization constraints
    constraint clk_tx_constr {
        nRST dist{ 0 := 1, 1 := 999};
    }

    function new(string name = "clk_transaction");
        super.new(name);
    endfunction //new()

endclass //clk_transaction extends uvm_sequence_item

`endif
