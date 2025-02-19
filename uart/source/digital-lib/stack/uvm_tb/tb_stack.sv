import uvm_pkg::*;
`include "socetlib_stack.sv"
`include "stack_if.svh"
`include "stack_test.svh"

//`timescale 1ns/1ps

module tb_stack();
    logic clk;

    //generate clock
    initial begin 
        clk = 0;
        forever #10 clk = ~clk;
    end

    stack_if s_if(clk);
    socetlib_stack DUT(s_if.clk, s_if.nRST, s_if.push, s_if.pop, s_if.clear, s_if.wdata, s_if.empty, s_if.full, s_if.overflow, s_if.underflow, s_if.count, s_if.rdata);

    initial begin 
        uvm_config_db#(virtual stack_if)::set(null, "", "stack_vif", s_if);
        run_test("test");
    end
endmodule
