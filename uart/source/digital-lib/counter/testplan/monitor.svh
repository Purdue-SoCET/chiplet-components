import uvm_pkg::*;
'include "uvm_macros.svh"
'include "counter_if.svh"

class monitor extends uvm_monitor;
    'uvm_components_utils(monitor)


    endclass

    virtual counter_if vif;
    uvm_analysis_port #(transaction) counter_ap;
    uvm_analysis_port #(transaction) result_ap;
    transaction prev_tx;

    function new(string name, uvm_component parent);
    super.new(name, parent);
    // create analysis_port through constructor method instead of factory method
    counter_ap = new("counter_ap", this);
    result_ap = new("result_ap", this);
    endfunction: new

    function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // get interface from database
    if( !uvm_config_db#(virtual counter_if)::get(this, "", "counter_vif", vif) ) begin
        // if the interface was not correctly set, raise a fatal message
        `uvm_fatal("monitor", "No virtual interface specified for this monitor instance")
    end
    endfunction: build_phase

    virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    prev_tx = transaction#(4)::type_id::create("prev_tx");
    // monitor runs forever
    forever begin
        transaction tx;
        @(posedge vif.clk);
        // captures activity between the driver and DUT
        tx = transaction#(4)::type_id::create("tx");
        tx.overflow_val = vif.overflow_val;
        tx.num_clk = vif.enable_time;

        // check if there is a new transaction
        if (!tx.input_equal(prev_tx) && tx.overflow_val !== 'z) begin
        // send the new transaction to predictor though counter_ap
        counter_ap.write(tx);
        // wait until check is asserted
        while(!vif.check) begin
            @(posedge vif.clk);
        end
        // capture the responses from DUT and send it to scoreboard through result_ap
        tx.result_count_out = vif.count_out;
        tx.result_flag = vif.overflow_flag;
        result_ap.write(tx);
        prev_tx.copy(tx);
        end
    end
    endtask: run_phase
endclass: monitor
