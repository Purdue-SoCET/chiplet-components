
module tb_socetlib_edge_detector;

    logic CLK = 0, nRST;
    
    localparam NBITS = 4;

    always #(10) CLK++;

    logic [NBITS-1:0] tb_signal, signal_last;
    logic [NBITS-1:0] tb_pos;
    logic [NBITS-1:0] tb_neg;
    int fails;

    socetlib_edge_detector #(.WIDTH(NBITS)) DUT(
        .CLK,
        .nRST,
        .signal(tb_signal),
        .pos_edge(tb_pos),
        .neg_edge(tb_neg)
    );

    task reset();
    begin
        nRST = 1'b0;
        repeat(2) @(negedge CLK);
        nRST = 1'b1;
        @(posedge CLK);
        #(1);
    end
    endtask


    initial begin
        $dumpfile("waveform.fst");
        $dumpvars(0, tb_socetlib_edge_detector);
        $timeformat(-9, 2, " ns", 20);

        tb_signal = 0;
        nRST = 1'b1;
        signal_last = 0;
        fails = 0;

        reset();

        if(tb_pos != (tb_signal & ~signal_last)) begin
            $display("Time %t [FAILED]: Posedge %b --> %b\n\tExpected %b, Actual %b\n", $time, signal_last, tb_signal, tb_signal & ~signal_last, tb_pos);
            fails++;
        end
        if(tb_neg != (~tb_signal & signal_last)) begin
            $display("Time %t [FAILED]: Negedge %b --> %b\n\tExpected %b, Actual %b\n", $time, signal_last, tb_signal, ~tb_signal & signal_last, tb_neg);
            fails++;
        end

        if(tb_pos != 0 || tb_neg != 0) begin
            $display("Time %t [FAILED]: Incorrect Reset value!\n", $time);
            fails++;
        end

        for(int i = 0; i < 100; i++) begin
            // Note: Edge detection done combinationally (i.e. *last* is latched, current input value determines if edge detected or not)
            signal_last = tb_signal;
            tb_signal = i;
            #(1);

            if(tb_pos != (tb_signal & ~signal_last)) begin
                $display("Time %t [FAILED]: Posedge %b --> %b\n\tExpected %b, Actual %b\n", $time, signal_last, tb_signal, tb_signal & ~signal_last, tb_pos);
                fails++;
            end
            if(tb_neg != (~tb_signal & signal_last)) begin
                $display("Time %t [FAILED]: Negedge %b --> %b\n\tExpected %b, Actual %b\n", $time, signal_last, tb_signal, ~tb_signal & signal_last, tb_neg);
                fails++;
            end
            
            @(posedge CLK);
            #(1);
        end

        tb_signal = {NBITS{1'b1}};
        signal_last = {NBITS{1'b1}};

        reset();

        if(tb_pos != (tb_signal & ~signal_last)) begin
            $display("Time %t [FAILED]: Posedge %b --> %b\n\tExpected %b, Actual %b\n", $time, signal_last, tb_signal, tb_signal & ~signal_last, tb_pos);
            fails++;
        end
        if(tb_neg != (~tb_signal & signal_last)) begin
            $display("Time %t [FAILED]: Negedge %b --> %b\n\tExpected %b, Actual %b\n", $time, signal_last, tb_signal, ~tb_signal & signal_last, tb_neg);
            fails++;
        end

        for(int i = 0; i < 100; i++) begin
            // Note: Edge detection done combinationally (i.e. *last* is latched, current input value determines if edge detected or not)
            signal_last = tb_signal;
            tb_signal = i;
            #(1);

            if(tb_pos != (tb_signal & ~signal_last)) begin
                $display("Time %t [FAILED]: Posedge %b --> %b\n\tExpected %b, Actual %b\n", $time, signal_last, tb_signal, tb_signal & ~signal_last, tb_pos);
                fails++;
            end
            if(tb_neg != (~tb_signal & signal_last)) begin
                $display("Time %t [FAILED]: Negedge %b --> %b\n\tExpected %b, Actual %b\n", $time, signal_last, tb_signal, ~tb_signal & signal_last, tb_neg);
                fails++;
            end

            @(posedge CLK);
            #(1);
        end

        if(fails == 0) begin
            $display("All tests passed!\n");
        end

        $finish();
    end

endmodule
