import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_if.svh"

class fifo_driver#(type T = logic [7:0], int DEPTH = 8) extends uvm_driver #(transaction#(T, DEPTH));
    `uvm_component_utils(fifo_driver#(T, DEPTH))

    virtual fifo_if#(T, DEPTH) vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fifo_if#(T, DEPTH))::get(this, "", "fifo_vif", vif)) begin
            `uvm_fatal("FIFO_Driver", "No virtual interface specified for this test instance");
        end
    endfunction

    task run_phase(uvm_phase phase);
        transaction#(T, DEPTH) req_item;
        DUT_reset();
        forever begin
            seq_item_port.get_next_item(req_item);
            @(posedge vif.clk);
            vif.WEN = req_item.WEN;
            vif.REN = req_item.REN;
            vif.clear = req_item.clear;
            vif.wdata = req_item.wdata;
            seq_item_port.item_done();
        end
    endtask

    task DUT_reset();
        @(posedge vif.clk);
        vif.nRST = 1;
        vif.REN = 0;
        vif.WEN = 0;
        vif.rdata = 0;
        vif.clear = 0;
        @(posedge vif.clk);
        vif.nRST = 0;
        @(posedge vif.clk);
        vif.nRST = 1;
    endtask
endclass //fifo_driver extends uvm_driver
