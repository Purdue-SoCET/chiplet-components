
module tb_socetlib_synchronizer();

    logic CLK = 0, nRST, async_in, sync_out;
    localparam TB_STAGES = 3;
    localparam TB_SENSE = 1'b1;

    always #(10) CLK++;

    logic window [$];
    logic expected;
    logic v;

    socetlib_synchronizer #(
        .STAGES(TB_STAGES),
        .RESET_STATE(TB_SENSE)
    ) DUT0 (
        .*
    );



    initial begin
        $dumpfile("waveform.fst");
        $dumpvars(0, tb_socetlib_synchronizer);
        $display("Running synchronizer with %d stages and %s reset value", TB_STAGES, TB_SENSE);
        async_in = (TB_SENSE == 1'b0) ? 1'b0 : 1'b1;
        nRST = 1'b1;
        @(negedge CLK);
        nRST = 1'b0;
        repeat(2) @(posedge CLK);
        @(negedge CLK);
        nRST = 1'b1;

        // Check reset value
        if(TB_SENSE == 1'b0) begin
            assert(sync_out == 1'b0)
            else $display("Incorrect reset value for SYNC_%s synchronizer", TB_SENSE);
        end else begin
            assert(sync_out == 1'b1)
            else $display("Incorrect reset value for SYNC_%s synchronizer", TB_SENSE);
        end

        for(int i = 0; i < 1000; i++) begin
            if(window.size >= TB_STAGES) begin
                expected = window.pop_back();
                assert(expected == sync_out)
                else begin
                    $display("At time %t, got %b, expected %b", $time, sync_out, expected);
                    $display("Window is: %p", window);
                end
            end

            v = $urandom;
            window.push_front(v);
            async_in = v;
            @(negedge CLK);
        end


        $finish();
    end

endmodule
