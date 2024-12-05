`include "socetlib_counter.sv"
`include "counter_if.svh"
`include "test.svh"

`timescale 1ns/1ps

import uvm_pkg::*;

module tb_counter ();
    logic clk;
  
  // generate clock
    initial begin
		clk = 0;
		forever #10 clk = !clk;
	end

    // instantiate interface and DUT
    counter_if ctr_if(clk);
    //socetlib_counter counter(.clk(ctr_if.counter.clk), .nRST(ctr_if.nRST), .clear(ctr_if.clear), .count_enable(ctr_if.count_enable), .overflow_val(ctr_if.overflow_val), .count_out(ctr_if.count_out), .overflow_flag(ctr_if.overflow_flag)); 
    socetlib_counter counter (ctr_if.counter);

    initial begin
        uvm_config_db#(virtual counter_if)::set( null, "", "counter_vif", ctr_if); // configure the interface into the database, so that it can be accessed throughout the hierachy
        run_test("test"); // initiate test component
    end
endmodule