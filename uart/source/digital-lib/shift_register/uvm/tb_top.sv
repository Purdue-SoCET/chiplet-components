`include "sr_if.svh"
`include "socetlib_shift_reg.sv"
`include "test.svh"
`timescale 1ns/1ps
import uvm_pkg::*;

module tb_top ();

  //Generate Clock for Testbench
  bit clk;
  always #10 clk <= ~clk;
  
  //Instantiate the Interface and Design
  sr_if dut_if(clk);
  socetlib_shift_reg dut(dut_if);	// Pass interface to DUT

  initial begin // Not sure what this block does
    uvm_config_db#(virtual sr_if)::set(null, "", "sr_if", dut_if);
    run_test("test");
  end
  
endmodule


