import uvm_pkg::*;
`include "uvm_macros.svh"
`include "stack_if.svh"

class stack_monitor#(type T = logic[7:0], parameter DEPTH = 8) extends uvm_monitor;
    `uvm_component_utils(stack_monitor#(T, DEPTH));
    virtual stack_if vif;
    
    uvm_analysis_port#(transaction) stack_ap;
    uvm_analysis_port#(transaction) result_ap;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        stack_ap = new("stack_ap", this);
        result_ap = new("result_ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual stack_if)::get(this, "", "stack_vif",vif))begin
            `uvm_fatal("STACK_MONITOR", "No virtual interface specified for this monitor instance.")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        //wait for DUT reset
        @(posedge vif.clk)
        `uvm_info(get_type_name(), $sformatf("sent vif.wdata:%d",vif.wdata), UVM_LOW)
        fork 
            begin
                `uvm_info(get_type_name(), $sformatf("sent vif.wdata:%d",vif.wdata), UVM_LOW)
                forever begin 
                    //read input and send to predictor
                    transaction tx;
                    @(posedge vif.clk)
                    tx = transaction#(T, DEPTH)::type_id::create("tx");
                    tx.nRST = vif.nRST;
                    tx.push = vif.push;
                    tx.pop = vif.pop;
                    tx.clear = vif.clear;
                    tx.wdata = vif.wdata;
                    stack_ap.write(tx);
                    `uvm_info(get_type_name(), $sformatf("sent tx.wdata:%d",tx.wdata), UVM_LOW)
                end
            end
            begin
            // read outputs and send to result_ap
                @(posedge vif.clk)
                forever begin
                    transaction tx;
                    @(posedge vif.clk)
                    tx = transaction#(T, DEPTH)::type_id::create("tx");
                    tx.full = vif.full;
                    tx.empty = vif.empty;
                    tx.overflow = vif.overflow;
                    tx.underflow = vif.underflow;
                    tx.count = vif.count;
                    tx.rdata = vif.rdata;
                    result_ap.write(tx);
                end
            end
        join_any
    endtask
endclass