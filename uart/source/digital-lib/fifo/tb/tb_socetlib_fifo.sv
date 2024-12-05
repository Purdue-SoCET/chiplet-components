`ifndef TB_WIDTH
    `define TB_WIDTH 8
`endif

`ifndef TB_DEPTH
    `define TB_DEPTH 8
`endif

module tb_socetlib_fifo();

    localparam ADDR_BITS = $clog2(`TB_DEPTH);

    logic CLK = 0, nRST;
    logic WEN, REN;
    logic clear, full, empty;
    logic [`TB_WIDTH-1:0] wdata, rdata;
    logic overrun, underrun;
    logic [ADDR_BITS-1:0] count;

    int tb_count;
    string tb_block;

    socetlib_fifo #(
        .T(logic [`TB_WIDTH-1:0]),
        .DEPTH(`TB_DEPTH)
    ) DUT (
        .*
    );

    always #(10) CLK++;

    task reset();
        @(negedge CLK);
        nRST = 1'b0;
        tb_count = '0;
        WEN = '0;
        REN = '0;
        clear = '0;
        wdata = '0;
        repeat(2) @(negedge CLK);
        nRST = 1'b1;
    endtask

    task check_count();
        if(tb_count < `TB_DEPTH) begin
            if (tb_count != count)
                $display("Incorrect count in block %s at time %t, expected %h, got %h",
                        tb_block, $time, tb_count, count);

            if (!(tb_count > 0 && !empty || empty))
                $display("'empty' flag incorrect in block %s at time %t", tb_block, $time);
        end else if(tb_count == `TB_DEPTH) begin
            if (!full)
                $display("'full' flag not asserted in block %s at time %t", tb_block, $time);

            if (empty)
                $display("'empty' flag incorrectly asserted in block %s at time %t", tb_block, $time);
        end else begin
            $error("tb_count higher than the data in the FIFO!");
        end
    endtask

    task read_fifo(
        input [`TB_WIDTH-1:0] expected_value
    );
        REN = 1'b1;
        if (rdata != expected_value)
            $display("Read (block %s): at time %t, expected %h, got %h",
                    tb_block, $time, expected_value, rdata);
        @(posedge CLK);
        #(1);
        REN = 1'b0;
        tb_count--;

        check_count();
    endtask

    task write_fifo(
        input [`TB_WIDTH-1:0] value
    );
        wdata = value;
        WEN = 1'b1;
        @(posedge CLK);
        #(1);
        WEN = 1'b0;
        tb_count++;

        check_count();
    endtask

    task read_write(
        input [`TB_WIDTH-1:0] value, expected_value
    );
        REN = 1'b1;
        WEN = 1'b1;
        if (rdata != expected_value)
            $display("Read/Write (block %s): at time %t, expected %h, got %h",
                    tb_block, $time, expected_value, rdata);

        wdata = value;
        @(posedge CLK);
        #(1);
        REN = 1'b0;
        WEN = 1'b0;
        // Count doesn't change here
        check_count();

    endtask

    initial begin
        $dumpfile("waveform.fst");
        $dumpvars(0, tb_socetlib_fifo);
        nRST = 1'b1;
        WEN = 1'b0;
        REN = 1'b0;
        clear = 1'b0;
        tb_count = 0;
        tb_block = "Initialization";

        tb_block = "Reset test";
        reset();
        @(negedge CLK);
        check_count();

        tb_block = "Fill/Empty";
        for(int i = 0; i < `TB_DEPTH; i++) begin
            write_fifo(i);
        end

        for(int i = 0; i < `TB_DEPTH; i++) begin
            read_fifo(i);
        end

        tb_block = "Check overrun";
        for(int i = 0; i < `TB_DEPTH; i++) begin
            write_fifo(i);
        end
        WEN = 1'b1;
        @(posedge CLK);
        #(1);
        if(!overrun)
            $display("Expected overrun flag to be set in block %s, time %t", tb_block, $time);

        tb_block = "Check clear";
        tb_count = 0;
        clear = 1'b1;
        @(posedge CLK);
        #(1);
        check_count();
        if (!(empty && !full && !overrun && !underrun))
            $display("FIFO Flags not reset correctly on clear in block %s, time %t", tb_block, $time);
        clear = 1'b0;


        tb_block = "Check underrun";
        REN = 1'b1;
        @(posedge CLK);
        #(1);
        if (!underrun)
            $display("Underrun flag not set in block %s, time %t", tb_block, $time);

        tb_block = "Resetting...";
        reset();

        tb_block = "Read and write simultaneously";
        write_fifo('1);
        read_write('0, '1);

        $finish();
    end

endmodule
