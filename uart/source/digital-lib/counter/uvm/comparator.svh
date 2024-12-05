import uvm_pkg::*;
`include "uvm_macros.svh"

class comparator extends uvm_scoreboard;
  `uvm_component_utils(comparator)
  uvm_analysis_export #(transaction) expected_export; // receive result from predictor
  uvm_analysis_export #(transaction) actual_export; // receive result from DUT
  uvm_tlm_analysis_fifo #(transaction) expected_fifo;
  uvm_tlm_analysis_fifo #(transaction) actual_fifo;

  int m_matches, m_mismatches; // records number of matches and mismatches

  function new(string name ,uvm_component parent);
		super.new( name , parent );
	  	m_matches = 0;
	  	m_mismatches = 0;
    endfunction

  function void build_phase( uvm_phase phase );
    expected_export = new("expected_export", this);
    actual_export = new("actual_export", this);
    expected_fifo = new("expected_fifo", this);
    actual_fifo = new("actual_fifo", this);
	endfunction: build_phase

  function void connect_phase(uvm_phase phase);
    expected_export.connect(expected_fifo.analysis_export);
    actual_export.connect(actual_fifo.analysis_export);
  endfunction: connect_phase

  task run_phase(uvm_phase phase);
    transaction expected_tx; //transaction from predictor
    transaction actual_tx;  //transaction from DUT
    /*uvm_report_info("Comparator", "before forever loop"); 
    expected_fifo.get(expected_tx);
    actual_fifo.get(actual_tx);
    uvm_report_info("Comparator", "got expected and actual");
   */ 
    forever begin
      expected_fifo.get(expected_tx);
      actual_fifo.get(actual_tx);
      uvm_report_info("Comparator", $psprintf("\nexpected:\nrollover_val: %d\nnum_clk: %d\ncount_out: %d\nflag: %d\n~~~~~~~~~~~~~~~~~~\nactual:\ncount_out: %d\nflag:%d\nenable: %d", expected_tx.overflow_val, expected_tx.num_clk, expected_tx.count_out, expected_tx.overflow_flag, actual_tx.count_out, actual_tx.overflow_flag, actual_tx.enable));
        //uvm_report_info("Testing...\n");    
        //uvm_report_info("Comparator", "entered loop"); 
      if(expected_tx.input_equal(actual_tx)) begin
        m_matches++;
        uvm_report_info("Comparator", "Data Match");
      end else begin
        m_mismatches++;
        uvm_report_error("Comparator", "Error: Data Mismatch");
      end
    end
    uvm_report_info("Comparator", "forever loop has ended");
  endtask

  function void report_phase(uvm_phase phase);
    uvm_report_info("Comparator", $sformatf("Matches:    %0d", m_matches));
    uvm_report_info("Comparator", $sformatf("Mismatches: %0d", m_mismatches));
  endfunction

endclass
