import uvm_pkg::*;
`include "socetlib_fifo.sv"
`include "fifo_if.svh"
`include "test.svh"

module tb_uvm_fifo();
    fifo_if#(int, 32) f_if();
    socetlib_fifo#(int, 32, $clog2(32)) DUT(f_if.clk, f_if.nRST, f_if.WEN, f_if.REN, f_if.clear, f_if.wdata, f_if.full, f_if.empty, f_if.underrun, f_if.overrun, f_if.count, f_if.rdata);

    initial begin
        uvm_config_db#(virtual fifo_if#(int, 32))::set(null, "", "fifo_vif", f_if);
        run_test();
    end
endmodule
