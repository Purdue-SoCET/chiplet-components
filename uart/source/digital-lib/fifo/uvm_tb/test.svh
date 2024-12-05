`ifndef TEST_SVH
`define TEST_SVH

import uvm_pkg::*;
`include "uvm_macros.svh"
`include "environment.svh"

class base_int_test extends uvm_test;
    `uvm_component_utils(base_int_test)
    environment#(int, 32) env;
    virtual fifo_if#(int, 32) vif;

    function new(string name = "base_int_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = environment#(int, 32)::type_id::create("env", this);

        if (!uvm_config_db#(virtual fifo_if#(int, 32))::get(this, "", "fifo_vif", vif)) begin
            `uvm_fatal("Test", "No virtual interface specified for this test instance")
        end

        uvm_config_db#(virtual fifo_if#(int, 32))::set(this, "env.agt*", "fifo_vif", vif);
    endfunction

    task run_phase(uvm_phase phase);
        fifo_seq#(int, 32) f_seq = fifo_seq#(int, 32)::type_id::create("f_seq", this);
        clk_seq#() c_seq = clk_seq#()::type_id::create("c_seq", this);

        phase.raise_objection(this, "Starting run_phase");
        $display("%t Starting sequence...", $time);
        fork
            begin
                c_seq.start(env.clk_agt.sqr);
            end
            begin
                f_seq.start(env.fifo_agt.sqr);
            end
        join
        #10ns
        phase.drop_objection(this, "Finished run_phase");
    endtask
endclass: base_int_test //base_int_test extends uvm_test

class period_10ns_test extends base_int_test;
    `uvm_component_utils(period_10ns_test)

    function new(string name = "period_10ns_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    task run_phase(uvm_phase phase);
        fifo_seq#(int, 32) f_seq = fifo_seq#(int, 32)::type_id::create("f_seq", this);
        clk_seq#(10) c_seq = clk_seq#(10)::type_id::create("c_seq", this);

        phase.raise_objection(this, "Starting run_phase");
        $display("%t Starting sequence...", $time);
        fork
            begin
                c_seq.start(env.clk_agt.sqr);
            end
            begin
                f_seq.start(env.fifo_agt.sqr);
            end
        join
        #10ns
        phase.drop_objection(this, "Finished run_phase");
    endtask
endclass: period_10ns_test //period_10ns_test extends base_int_test

class period_20ns_test extends base_int_test;
    `uvm_component_utils(period_20ns_test)

    function new(string name = "period_20ns_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    task run_phase(uvm_phase phase);
        fifo_seq#(int, 32) f_seq = fifo_seq#(int, 32)::type_id::create("f_seq", this);
        clk_seq#(20) c_seq = clk_seq#(20)::type_id::create("c_seq", this);

        phase.raise_objection(this, "Starting run_phase");
        $display("%t Starting sequence...", $time);
        fork
            begin
                c_seq.start(env.clk_agt.sqr);
            end
            begin
                f_seq.start(env.fifo_agt.sqr);
            end
        join
        #10ns
        phase.drop_objection(this, "Finished run_phase");
    endtask
endclass: period_20ns_test //period_20ns_test extends base_int_test

class read_write_test extends base_int_test;
    `uvm_component_utils(read_write_test)

    function new(string name = "read_write_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    task run_phase(uvm_phase phase);
        read_write_fifo_seq#(int, 32) f_seq = read_write_fifo_seq#(int, 32)::type_id::create("f_seq", this);
        clk_seq#(10, 2 * (32 + 1)) c_seq = clk_seq#(10, 2 * (32 + 1))::type_id::create("c_seq", this);

        phase.raise_objection(this, "Starting run_phase");
        $display("%t Starting sequence...", $time);
        fork
            begin
                c_seq.start(env.clk_agt.sqr);
            end
            begin
                f_seq.start(env.fifo_agt.sqr);
            end
        join
        #10ns
        phase.drop_objection(this, "Finished run_phase");
    endtask
endclass //read_write_test extends base_int_test

class clear_test extends base_int_test;
    `uvm_component_utils(clear_test)

    function new(string name = "clear_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    task run_phase(uvm_phase phase);
        clear_fifo_seq#(int, 32) f_seq = clear_fifo_seq#(int, 32)::type_id::create("f_seq", this);
        clk_seq#(10, 3 + (32 / 2) + 32 + 1) c_seq = clk_seq#(10, 3 + (32 / 2) + 32 + 1)::type_id::create("c_seq", this);

        phase.raise_objection(this, "Starting run_phase");
        $display("%t Starting sequence...", $time);
        fork
            begin
                c_seq.start(env.clk_agt.sqr);
            end
            begin
                f_seq.start(env.fifo_agt.sqr);
            end
        join
        #10ns
        phase.drop_objection(this, "Finished run_phase");
    endtask
endclass //clear_test extends base_int_test

class nrst_test extends base_int_test;
    `uvm_component_utils(nrst_test)

    function new(string name = "nrst_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    task run_phase(uvm_phase phase);
        fifo_seq#(int, 32, 40) f_seq = fifo_seq#(int, 32, 40)::type_id::create("f_seq", this);
        nrst_clk_seq#(10) c_seq = nrst_clk_seq#(10)::type_id::create("c_seq", this);

        phase.raise_objection(this, "Starting run_phase");
        $display("%t Starting sequence...", $time);
        fork
            begin
                c_seq.start(env.clk_agt.sqr);
            end
            begin
                f_seq.start(env.fifo_agt.sqr);
            end
        join
        #10ns
        phase.drop_objection(this, "Finished run_phase");
    endtask
endclass //nrst_test extends base_int_test

class full_random_test extends base_int_test;
    `uvm_component_utils(full_random_test)

    function new(string name = "full_random_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    task run_phase(uvm_phase phase);
        fifo_seq#(int, 32, 20001) f_seq = fifo_seq#(int, 32, 20001)::type_id::create("f_seq", this);
        clk_seq#(10, 20001) c_seq = clk_seq#(10, 20001)::type_id::create("c_seq", this);

        phase.raise_objection(this, "Starting run_phase");
        $display("%t Starting sequence...", $time);
        fork
            begin
                c_seq.start(env.clk_agt.sqr);
            end
            begin
                f_seq.start(env.fifo_agt.sqr);
            end
        join
        #10ns
        phase.drop_objection(this, "Finished run_phase");
    endtask
endclass //full_random_test extends base_int_test
/*
class sixteen_bit_test extends uvm_test;
    `uvm_component_utils(sixteen_bit_test);
    environment#(logic [15:0], 16) env;
    virtual fifo_if#(logic [15:0], 16) vif;
    fifo_seq#(logic [15:0], 16) f_seq;
    clk_seq#(10) c_seq;

    function new(string name = "sixteen_bit_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = environment#(logic [15:0], 16)::type_id::create("env", this);
        f_seq = fifo_seq#(logic [15:0], 16)::type_id::create("f_seq", this);
        c_seq = clk_seq#(10)::type_id::create("c_seq", this);

        if (!uvm_config_db#(virtual fifo_if#(logic [15:0], 16))::get(this, "", "fifo_vif", vif)) begin
            `uvm_fatal("Test", "No virtual interface specified for this test instance")
        end

        uvm_config_db#(virtual fifo_if#(logic [15:0], 16))::set(this, "env.agt*", "fifo_vif", vif);
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this, "Starting run_phase");
        $display("%t Starting sequence...", $time);
        fork
            begin
                c_seq.start(env.clk_agt.sqr);
            end
            begin
                f_seq.start(env.fifo_agt.sqr);
            end
        join
        #10ns
        phase.drop_objection(this, "Finished run_phase");
    endtask
endclass: sixteen_bit_test //sixteen_bit_test extends uvm_test
*/
`endif
