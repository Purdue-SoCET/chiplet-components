import uvm_pkg::*;
`include "uvm_macros.svh"
`include "clk_transaction.svh"
`timescale 1ns/1ns

class clk_seq#(PERIOD = 10, CYCLES = 101) extends uvm_sequence#(clk_transaction);
    `uvm_object_param_utils(clk_seq#(PERIOD, CYCLES))

    function new(string name = "");
        super.new(name);
    endfunction //new()

    task body();
        clk_transaction req_item;
        req_item = clk_transaction::type_id::create("req_item");
    
        repeat(CYCLES) begin
            #(PERIOD/2)
            start_item(req_item);
            req_item.clk = 1;
            finish_item(req_item);
            #(PERIOD/2)
            start_item(req_item);
            req_item.clk = 0;
            finish_item(req_item);
        end
    endtask
endclass //clk_seq extends uvm_sequence

class nrst_clk_seq#(PERIOD = 10) extends uvm_sequence#(clk_transaction);
    `uvm_object_param_utils(nrst_clk_seq#(PERIOD))

    function new(string name = "");
        super.new(name);
    endfunction //new()

    task body();
        clk_transaction req_item;
        req_item = clk_transaction::type_id::create("req_item");
    
        repeat(10) begin
            #(PERIOD/2)
            start_item(req_item);
            req_item.clk = 1;
            finish_item(req_item);
            #(PERIOD/2)
            start_item(req_item);
            req_item.clk = 0;
            finish_item(req_item);
        end

        #(PERIOD/2)
        start_item(req_item);
        req_item.clk = 1;
        req_item.nRST = 0;
        finish_item(req_item);
        #(PERIOD/2)
        start_item(req_item);
        req_item.clk = 0;
        req_item.nRST = 0;
        finish_item(req_item);

        repeat(20) begin
            #(PERIOD/2)
            start_item(req_item);
            req_item.clk = 1;
            finish_item(req_item);
            #(PERIOD/2)
            start_item(req_item);
            req_item.clk = 0;
            finish_item(req_item);
        end

        #(PERIOD/2)
        start_item(req_item);
        req_item.clk = 1;
        req_item.nRST = 0;
        finish_item(req_item);
        #(PERIOD/2)
        start_item(req_item);
        req_item.clk = 0;
        req_item.nRST = 0;
        finish_item(req_item);

        repeat(10) begin
            #(PERIOD/2)
            start_item(req_item);
            req_item.clk = 1;
            finish_item(req_item);
            #(PERIOD/2)
            start_item(req_item);
            req_item.clk = 0;
            finish_item(req_item);
        end
    endtask
endclass //nrst_clk_seq extends uvm_sequence

class clk_sequencer extends uvm_sequencer#(clk_transaction);
    `uvm_component_utils(clk_sequencer)

    function new(string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()
endclass //clk_sequencer extends uvm_sequencer
