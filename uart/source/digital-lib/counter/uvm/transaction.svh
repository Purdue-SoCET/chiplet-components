`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

class transaction #(parameter BITS_WIDTH = 4) extends uvm_sequence_item;
    rand bit [BITS_WIDTH - 1 : 0] overflow_val;
    rand int num_clk;
    bit [BITS_WIDTH - 1 : 0] count_out;
    bit overflow_flag;
    bit enable;

    `uvm_object_utils_begin(transaction)
        `uvm_field_int(overflow_val, UVM_NOCOMPARE)
        `uvm_field_int(num_clk, UVM_NOCOMPARE)
        `uvm_field_int(count_out, UVM_DEFAULT)
        `uvm_field_int(overflow_flag, UVM_DEFAULT)
    `uvm_object_utils_end

    constraint overflow{overflow_val != 0; overflow_val != 1;}
    constraint clk_number{num_clk > 0; num_clk < 20;}

    function new(string name = "transaction");
        super.new(name);
    endfunction: new

   function int input_equal(transaction tx);
    int result;
    if ((overflow_val == tx.overflow_val) && (num_clk == tx.num_clk)) begin
        result = 1;
        return result;
    end
    result = 0;
    return result;
    endfunction

endclass

`endif
