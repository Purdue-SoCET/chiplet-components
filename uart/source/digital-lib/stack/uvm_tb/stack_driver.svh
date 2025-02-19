import uvm_pkg::*;
`include "uvm_macros.svh"
`include "stack_if.svh"

class stack_driver#(type T = logic [7:0], int DEPTH = 8) extends uvm_driver #(transaction);
    `uvm_component_utils(stack_driver);
    virtual stack_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if(!uvm_config_db#(virtual stack_if)::get(this, "", "stack_vif", vif))begin
            `uvm_fatal("STACK_DRIVER", "No virtual interface specified for this test instance")
        end 
    endfunction

    task run_phase(uvm_phase phase);
        transaction req_item;
        DUT_reset();
        forever begin
            seq_item_port.get_next_item(req_item);
            vif.nRST = req_item.nRST;
            vif.push = req_item.push;
            vif.pop = req_item.pop;
            vif.clear = req_item.clear;
            vif.wdata = req_item.wdata;
            `uvm_info(get_type_name(), $sformatf("wdata after fetch: %d", vif.wdata), UVM_LOW);
            @(posedge vif.clk);
            seq_item_port.item_done();
        end
    endtask
    
    task DUT_reset();
        @(posedge vif.clk);
        vif.nRST = 1;
        vif.push = 0;
        vif.pop = 0;
        vif.rdata = 0;
        vif.wdata = 0;
        vif.clear = 0;
        @(posedge vif.clk);
        vif.nRST = 0;
        @(posedge vif.clk);
        vif.nRST = 1;
        @(posedge vif.clk);
        `uvm_info(get_type_name(), $sformatf("done with reset."), UVM_LOW);
        `uvm_info(get_type_name(), $sformatf("nRST after reset: %d", vif.nRST), UVM_LOW);
    endtask

endclass