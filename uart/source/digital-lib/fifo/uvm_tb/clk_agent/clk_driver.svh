import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_if.svh"

class clk_driver#(type T = logic [7:0], int DEPTH = 8) extends uvm_driver#(clk_transaction);
    `uvm_component_utils(clk_driver#(T, DEPTH))

    virtual fifo_if#(T, DEPTH) vif;

    function new(string name = "", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual fifo_if#(T, DEPTH))::get(this, "", "fifo_vif", vif)) begin
            `uvm_fatal("CLK_Driver", "No virtual interface specified for this test instance");
        end
    endfunction

    task run_phase(uvm_phase phase);
        clk_transaction req_item;
        DUT_reset();
        forever begin
            seq_item_port.get_next_item(req_item);
            vif.nRST = req_item.nRST;
            vif.clk = req_item.clk;  // drive clock
            seq_item_port.item_done();
        end
    endtask

    task DUT_reset();
        // drive clock 3 cycles
        vif.clk = 0;
        repeat(3) begin
            vif.clk = 1;
            #10ns
            vif.clk = 0;
            #10ns
            vif.clk = 1;
        end
    endtask
endclass //clk_driver extends uvm_driver
