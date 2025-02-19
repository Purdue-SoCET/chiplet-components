import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_transaction.svh"

class predictor #(type T = logic [7:0], int DEPTH = 8) extends uvm_subscriber#(transaction#(T, DEPTH));
    `uvm_component_utils(predictor#(T, DEPTH))

    uvm_analysis_port#(transaction#(T, DEPTH)) pred_ap;
    transaction#(T, DEPTH) pred_tx;
    T pred_fifo [$:DEPTH - 1];  // model fifo with DEPTH size
    int size;
    bit curr_underrun, curr_overrun, prev_underrun, prev_overrun = 0;
    T temp, first_data = 0;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        pred_ap = new("pred_ap", this);
    endfunction

    function void write(transaction#(T, DEPTH) t);
        prev_overrun = curr_overrun;  // overrun persists until clear or !nRST
        prev_underrun = curr_underrun;  // underrun persists until clear or !nRST

        pred_tx = transaction#(T, DEPTH)::type_id::create("pred_tx", this);
        pred_tx.copy(t);

        // Calculate expected output
        size = pred_fifo.size();
        if (t.REN) begin  // attempt to read data
            if (size == 0) begin
                pred_tx.underrun = 1;
                curr_underrun = 1;
            end else begin
                pred_tx.underrun = 0;
                curr_underrun = 0;
                temp = pred_fifo.pop_front();
            end
        end
        
        if (t.WEN) begin  // attempt to write data
            if (size == DEPTH) begin
                pred_tx.overrun = 1;
                curr_overrun = 1;
            end else begin
                if (size == 0) begin  // if buffer was empty, data written is in base position
                    first_data = t.wdata;
                end
                pred_tx.overrun = 0;
                curr_overrun = 0;
                pred_fifo.push_back(t.wdata);
            end
        end
        
        size = pred_fifo.size();
        pred_tx.count = size;

        if (size == DEPTH) begin  // full assignment
            pred_tx.full = 1;
        end else begin
            pred_tx.full = 0;
        end

        if (size == 0) begin  // empty and rdata assignment
            pred_tx.empty = 1;
            pred_tx.rdata = first_data;  // if empty, rdata is 0
        end else begin
            pred_tx.empty = 0;
            pred_tx.rdata = pred_fifo[0];
        end

        if (prev_overrun) begin  // overrrun assignment based on previous state
            pred_tx.overrun = 1;
            curr_overrun = 1;
        end
        if (prev_underrun) begin  // underrun assignment based on previous state
            pred_tx.underrun = 1;
            curr_underrun = 1;
        end

        if (t.clear || !t.nRST) begin  // clear or !nRST - set to default states
            if (!t.nRST) begin
                first_data = '0;  // !nRST resets FIFO state
            end
            pred_tx.rdata = first_data;  // buffer doesn't reset data, just resets pointer
            pred_tx.count = 0;
            pred_tx.empty = 1;
            pred_tx.full = 0;
            pred_tx.overrun = 0;
            pred_tx.underrun = 0;
            pred_fifo = {};
            curr_overrun = 0;
            curr_underrun = 0;
        end

        pred_ap.write(pred_tx);
    endfunction
endclass //predictor extends uvm_subscriber
