
import uvm_pkg::*;
`include "uvm_macros.svh"

class scoreboard extends uvm_scoreboard;
    `uvm_component_utils(scoreboard)

    function new( string name , uvm_component parent) ;
	    super.new(name, parent);
 	endfunction

    bit[3:0] ref_byte;
    bit[3:0] act_byte;
    bit[3:0] exp_byte;

    uvm_analysis_imp #(transaction, scoreboard) m_analysis_imp;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        m_analysis_imp = new("m_analysis_imp", this);
    endfunction

    virtual function write(transaction tx);
        act_byte = act_byte << 1 | tx.serial_in;

        exp_byte = 4'hf;
        if (tx.nRST)
            exp_byte = 4'hf;
        else
            exp_byte = exp_byte << 1 | tx.serial_in;

        if (tx.parallel_out != exp_byte) begin
            `uvm_fatal("SCBD", $sformatf("Error, out=0b%0b exp=0b%0b", tx.parallel_out, exp_byte))
        end else begin
            `uvm_info("SCBD", $sformatf("Pass, out=%0b exp=0b%0b", tx.parallel_out, exp_byte), UVM_HIGH)
        end


    endfunction 

endclass