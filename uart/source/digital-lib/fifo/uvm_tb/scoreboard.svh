import uvm_pkg::*;
`include "uvm_macros.svh"

class scoreboard#(type T = logic [7:0], int DEPTH = 8) extends uvm_scoreboard;
    `uvm_component_utils(scoreboard#(T, DEPTH))
    uvm_analysis_export#(transaction#(T, DEPTH)) expected_export;
    uvm_analysis_export#(transaction#(T, DEPTH)) actual_export;
    uvm_tlm_analysis_fifo#(transaction#(T, DEPTH)) expected_fifo;
    uvm_tlm_analysis_fifo#(transaction#(T, DEPTH)) actual_fifo;

    int num_matches, num_mismatches;

    function new(string name, uvm_component parent = null);
        super.new(name, parent);
        num_matches = 0;
        num_mismatches = 0;
    endfunction //new()

    function void build_phase(uvm_phase phase);
        expected_export = new("expected_export", this);
        actual_export = new("actual_export", this);
        expected_fifo = new("expected_fifo", this);
        actual_fifo = new("actual_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        expected_export.connect(expected_fifo.analysis_export);
        actual_export.connect(actual_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        transaction#(T, DEPTH) ex_tx;  // expected transaction
        transaction#(T, DEPTH) act_tx;  // actual transaction
        forever begin
            expected_fifo.get(ex_tx);
            actual_fifo.get(act_tx);
            uvm_report_info("Scoreboard", $psprintf("\nInput:\nwdata: %d\nWEN: %d\nREN: %d\nclear: %d\n---",
                                                    ex_tx.wdata, ex_tx.WEN, ex_tx.REN, ex_tx.clear), UVM_MEDIUM);
            uvm_report_info("Scoreboard", $psprintf("\nExpected:\nfull: %d\nempty: %d\noverrun: %d\nunderrun: %d\ncount: %d\nrdata: %d\n~~~~~~~~~~\nActual:\nfull: %d\nempty: %d\noverrun: %d\nunderrun: %d\ncount: %d\nrdata: %d\n",
                                                    ex_tx.full, ex_tx.empty, ex_tx.overrun, ex_tx.underrun, ex_tx.count, ex_tx.rdata,
                                                    act_tx.full, act_tx.empty, act_tx.overrun, act_tx.underrun, act_tx.count, act_tx.rdata), UVM_MEDIUM);
            // keep count of number of matches and mismatches (actual vs expected)
            if (!ex_tx.count && !act_tx.count) begin  // rdata insignificant when count = 0
                ex_tx.rdata = 0;
                act_tx.rdata = 0;
            end
            if (ex_tx.compare(act_tx)) begin
                num_matches++;
                uvm_report_info("Scoreboard", "Data match");
            end else begin
                num_mismatches++;
                uvm_report_info("Scoreboard", "Error: Data mismatch");
            end
        end
    endtask

    function void report_phase(uvm_phase phase);
        uvm_report_info("Scoreboard", $psprintf("Matches:    %d", num_matches), UVM_LOW);
        uvm_report_info("Scoreboard", $psprintf("Mismatches: %d", num_mismatches), UVM_LOW);
    endfunction
endclass //scoreboard extends uvm_scoreboard
