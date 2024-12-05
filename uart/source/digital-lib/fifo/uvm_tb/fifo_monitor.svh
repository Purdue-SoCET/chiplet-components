import uvm_pkg::*;
`include "uvm_macros.svh"
`include "fifo_if.svh"

class fifo_monitor #(type T = logic [7:0], int DEPTH = 8) extends uvm_monitor;
    `uvm_component_utils(fifo_monitor#(T, DEPTH))

    virtual fifo_if#(T, DEPTH) vif;

    uvm_analysis_port#(transaction#(T, DEPTH)) fifo_ap;
    uvm_analysis_port#(transaction#(T, DEPTH)) result_ap;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        fifo_ap = new("fifo_ap", this);
        result_ap = new("result_ap", this);        
    endfunction //new()

    virtual function void build_phase(uvm_phase phase);
        if (!uvm_config_db#(virtual fifo_if#(T, DEPTH))::get(this, "", "fifo_vif", vif)) begin
            `uvm_fatal("FIFO_Monitor", "No virtual interface specified for this monitor instance")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        // wait for DUT reset
        @(posedge vif.clk)
        @(posedge vif.clk)

        fork
            begin  // input read / predictor thread
                forever begin
                    // read inputs and send to fifo_ap (to predictor)
                    transaction#(T, DEPTH) tx;
                    @(posedge vif.clk)
                    tx = transaction#(T, DEPTH)::type_id::create("tx");
                    tx.nRST = vif.nRST;
                    tx.WEN = vif.WEN;
                    tx.REN = vif.REN;
                    tx.clear = vif.clear;
                    tx.wdata = vif.wdata;
                    fifo_ap.write(tx);
                end
            end
            begin  // output read / actual output thread
                @(posedge vif.clk)  // wait clk cycles to read outputs
                @(posedge vif.clk)  // - until output is affected by input
                forever begin
                    // read outputs and send to result_ap (to scoreboard)
                    transaction#(T, DEPTH) tx;
                    @(posedge vif.clk)
                    tx = transaction#(T, DEPTH)::type_id::create("tx");
                    tx.full = vif.full;
                    tx.empty = vif.empty;
                    tx.overrun = vif.overrun;
                    tx.underrun = vif.underrun;
                    tx.count = vif.count;
                    tx.rdata = vif.rdata;
                    result_ap.write(tx);
                end
            end
        join
    endtask
endclass //fifo_monitor extends uvm_monitor
