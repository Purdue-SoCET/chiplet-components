import uvm_pkg::*;
`include "uvm_macros.svh"

class scoreboard#(type T = logic[7:0], parameter DEPTH = 8)extends uvm_scoreboard;
    `uvm_component_utils(scoreboard#(T, DEPTH));
    uvm_analysis_export#(transaction#(T, DEPTH)) expected_export;
    uvm_analysis_export#(transaction#(T, DEPTH)) actual_export;
    uvm_tlm_analysis_fifo#(transaction#(T, DEPTH)) expected_fifo;
    uvm_tlm_analysis_fifo#(transaction#(T, DEPTH)) actual_fifo;

    int num_matches, num_mismatches, num_push, num_pop, num_clear, num_nRST;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        num_mismatches = 0;
        num_matches = 0;
        num_push = 0; num_pop = 0; num_clear = 0; num_nRST = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);
        expected_fifo = new("expected_fifo", this);
        actual_fifo = new("actual_fifo", this);
    endfunction

    function void connect_phase (uvm_phase phase);
        expected_export.connect(expected_fifo.analysis_export);
        actual_export.connect(actual_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        transaction#(T, DEPTH) ex_tx;
        transaction#(T, DEPTH) act_tx;
        `uvm_info(get_type_name(), $sformatf("Start scoreboard process."), UVM_LOW);
        forever begin
            expected_fifo.get(ex_tx);
            actual_fifo.get(act_tx);
            `uvm_info(get_type_name(), $psprintf("\nInput:\nwdata: %d\npush: %d\npop: %d\nclear: %d\nnRST: %d\n---",
                                                   ex_tx.wdata, ex_tx.push, ex_tx.pop, ex_tx.clear, ex_tx.nRST), UVM_LOW);
            `uvm_info(get_type_name(), $psprintf("\nExpected:\nfull: %d\nempty: %d\noverrun: %d\nunderrun: %d\ncount: %d\nrdata: %d\n~~~~~~~~~~\nActual:\nfull: %d\nempty: %d\noverrun: %d\nunderrun: %d\ncount: %d\nrdata: %d\n--------------\n",
                                                   ex_tx.full, ex_tx.empty, ex_tx.overflow, ex_tx.underflow, ex_tx.count, ex_tx.rdata,
                                                   act_tx.full, act_tx.empty, act_tx.overflow, act_tx.underflow, act_tx.count, act_tx.rdata), UVM_LOW);

            if (!ex_tx.count && !act_tx.count) begin
                ex_tx.rdata = 0;
                act_tx.rdata = 0;
            end

            if (ex_tx.push == 1) begin
                num_push++;
            end
            if (ex_tx.pop == 1) begin
                num_pop++;
            end
            if (ex_tx.clear == 1) begin
                num_clear++;
            end
            if (ex_tx.nRST == 0) begin
                num_nRST++;
            end

            if(ex_tx.rdata == act_tx.rdata & ex_tx.full == act_tx.full & ex_tx.empty == act_tx.empty & ex_tx.overflow == act_tx.overflow & ex_tx.underflow == act_tx.underflow &ex_tx.count == act_tx.count) begin
                num_matches++;
                `uvm_info(get_type_name(), $sformatf("DATA MATCHED"), UVM_LOW);
            end else begin
                num_mismatches++;
                `uvm_info(get_type_name(), $sformatf("DATA MISMATCHED"), UVM_LOW);
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        uvm_report_info("Scoreboard", $psprintf("Matches:   %d", num_matches), UVM_LOW);
        uvm_report_info("Scoreboard", $psprintf("Mismatches:%d", num_mismatches), UVM_LOW);
        uvm_report_info("Scoreboard", $psprintf("\npush:   %d\npop:    %d\nclear:  %d\nnRST:   %d",num_push,num_pop, num_clear,num_nRST), UVM_LOW);
        if (num_matches > 0 & num_mismatches == 0) begin
            uvm_report_info("Scoreboard", $psprintf("Test passed!"), UVM_LOW);
        end else begin
            uvm_report_info("Scoreboard", $psprintf("Test failed!"), UVM_LOW);
        end
    endfunction
endclass 