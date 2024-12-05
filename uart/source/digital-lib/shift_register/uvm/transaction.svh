`ifndef TRANSACTION_SVH
`define TRANSACTION_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"

class transaction #(parameter BITS_WIDTH = 4) extends uvm_sequence_item;
    rand bit [BITS_WIDTH - 1 : 0] parallel_in;
    rand bit serial_in;
    bit shift_en;
    rand bit parallel_en;
    rand int num_clk;

    bit [BITS_WIDTH - 1 : 0] parallel_out;
    bit serial_out;


    `uvm_object_utils_begin(transaction)
        
    `uvm_object_utils_end

    constraint parallel {parallel_in <= 2**(BITS_WIDTH - 1); parallel_in >= 0;}
    constraint serial { serial_in dist {0:/50, 1:/50}; }

    virtual function string convert2str();
        return $sformatf("in=%0d", serial_in); 
    endfunction

    function new(string name = "transaction");
        super.new(name);
    endfunction: new

endclass

`endif
