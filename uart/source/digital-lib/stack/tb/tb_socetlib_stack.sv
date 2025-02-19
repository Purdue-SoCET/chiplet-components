`ifndef TB_WIDTH
    `define TB_WIDTH 8
`endif

`ifndef TB_DEPTH
    `define TB_DEPTH 8
`endif

module tb_socetlib_stack();


    logic CLK = 0, nRST;
    logic push, pop, clear;
    logic empty, full;
    logic overflow, underflow;
    logic [$clog2(`TB_DEPTH):0] count;
    logic [`TB_WIDTH-1:0] wdata, rdata;

    int tb_count;
    string tb_block;

    socetlib_stack #(
        .T(logic [`TB_WIDTH-1:0]),
        .DEPTH(`TB_DEPTH)
    ) DUT(
        .*
    );

    task reset();
        @(negedge CLK);
        nRST = 1'b0;
        repeat(2) @(negedge CLK);
        nRST = 1'b1;
        @(posedge CLK);
    endtask

    task check_count();
        assert(tb_count == count)
        else $display("(Block %s, time %t) Incorrect count, expected %x, got %x\n", tb_block, $time, tb_count, count);

        if(tb_count == `TB_DEPTH) begin
            assert(full && !empty)
            else $display("(Block %s, time %t) Full stack has incorrect flags!\n", tb_block, $time);
        end

        if(tb_count == 0) begin
            assert(empty && !full)
            else $display("(Block %s, time %t) Empty stack has incorrect flags!\n", tb_block, $time);
        end
    endtask

    task stack_push(
        input [`TB_WIDTH-1:0] value
    );
        wdata = value;
        push = 1'b1;
        @(posedge CLK);
        #(1);
        tb_count++;
        check_count();
    endtask

    task stack_pop(
        input [`TB_WIDTH-1:0] expected_value
    );
        assert(rdata == expected_value)
        else $display("(Block %s, time %t) Incorrect data on pop, expected %x, got %x\n", tb_block, $time, expected_value, rdata);

        pop = 1'b1;
        @(posedge CLK);
        #(1);
        tb_count--;
        check_count();
    endtask

    task push_pop(
        input [`TB_WIDTH-1:0] value, expected_value
    );
        assert(rdata == expected_value)
        else $display("(Block %s, time %t) Incorrect data on pop, expected %x, got %x\n", tb_block, $time, expected_value, rdata);
        pop = 1'b1;
        push = 1'b1;
        wdata = value;
        @(posedge CLK);
        #(1);
        check_count();
    endtask


    initial begin
        $dumpfile("waveform.fst");
        $dumpvars(0, tb_socetlib_stack);
        nRST = 1'b1;
        clear = 1'b0;
        push = 1'b0;
        pop = 1'b0;
        tb_count = 0;
        tb_block = "Initializing";

        tb_block = "Reset check";
        reset();
        assert(empty && !full)
        else $display("Incorrect flags on reset!\n");

        tb_block = "Push to full, pop to empty";
        for(int i = 0; i < `TB_DEPTH; i++) begin
            stack_push(i);
        end

        // Have to reverse output, LIFO
        for(int i = `TB_DEPTH-1; i >= 0; i--) begin
            stack_pop(i);
        end

        tb_block = "Check clear";
        clear = 1'b1;
        @(posedge CLK);
        #(1);
        clear = 1'b0;
        tb_count = 0;
        check_count();
        assert(!overflow && !underflow && !full && empty)
        else $display("(Block %s, time %t) Incorrect flags after clear\n", tb_block, $time);

        tb_block = "Push and pop simultaneously";
        stack_push('1);
        push_pop('0, '1);
        stack_pop('0);

        tb_block = "Resetting";
        reset();

        tb_block = "Check underflow";
        pop = 1'b1;
        @(posedge CLK);
        #(1);
        pop = 1'b0;
        assert(underflow)
        else $display("(Block %s, time %t) Did not get underflow flag\n", tb_block, $time);

        tb_block = "Resetting";
        reset();
        
        tb_block = "Check overflow";
        for(int i = 0; i < `TB_DEPTH; i++) begin
            stack_push(i);
        end

        push = 1'b1;
        @(posedge CLK);
        #(1);
        push = 1'b0;
        assert(underflow)
        else $display("(Block %s, time %t) Did not get overflow flag\n", tb_block, $time);

        $finish();
    end

endmodule
