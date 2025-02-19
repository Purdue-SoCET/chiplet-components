import uvm_pkg::*;
`include "uvm_macros.svh"
`include "transaction.svh"

class predictor extends uvm_subscriber #(transaction);
    `uvm_component_utils(predictor)
    
    uvm_analysis_port #(transaction) pred_ap;
    transaction output_tx;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        pred_ap = new("pred_ap", this);
    endfunction

    function void write(transaction t);
        output_tx = transaction#(4)::type_id::create("output_tx", this);
        output_tx.copy(t);
        output_tx.count_out = 0;
        for (int lcv = 0; lcv < t.num_clk; lcv++) begin
            output_tx.count_out++;
            // inverrted
            if (output_tx.count_out == t.overflow_val + 1) begin
                output_tx.count_out = 0;
            end
        end
        
        if (output_tx.count_out == t.overflow_val) begin
            output_tx.overflow_flag = 1;
        end
        else begin
            output_tx.overflow_flag = 0;
        end

        pred_ap.write(output_tx);
    endfunction :write

endclass: predictor
