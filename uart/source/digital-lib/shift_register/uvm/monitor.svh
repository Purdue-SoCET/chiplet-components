
import uvm_pkg::*;
`include "uvm_macros.svh"
`include "sr_if.svh"
class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)

    function new(string name, uvm_component parent = null);
    super.new(name, parent);
    endfunction

    uvm_analysis_port #(transaction) mon_analysis_port;
    virtual sr_if vif;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual sr_if)::get(this, "", "sr_if", vif))
            `uvm_fatal("MON", "Could not get vif")
        mon_analysis_port = new("mon_analysis_port", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            @ (vif.clk);
            if (vif.nRST) begin
                transaction tx = transaction#(4)::type_id::create("tx");
                tx.serial_in = vif.serial_in;
                tx.parallel_out = vif.parallel_out;
                mon_analysis_port.write(tx);
                `uvm_info("MON", $sformatf("Saw item %s", tx.convert2str()), UVM_HIGH);

            end
        end
    endtask

endclass