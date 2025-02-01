`define BIND_SWITCH_TRACKER(name)                                                               \
    bind switch switch_tracker #(                                                               \
        .NUM_OUTPORTS(NUM_OUTPORTS),                                                            \
        .NUM_BUFFERS(NUM_BUFFERS),                                                              \
        .NUM_VCS(NUM_VCS),                                                                      \
        .BUFFER_SIZE(BUFFER_SIZE),                                                              \
        .TOTAL_NODES(TOTAL_NODES),                                                              \
        .NODE(NODE)                                                                             \
    ) TRACK_``name (                                                                            \
        .clk(clk),                                                                              \
        .nrst(n_rst),                                                                           \
        .not_idle(buf_if.req_routing | buf_if.req_vc | buf_if.req_switch | buf_if.req_crossbar),\
        .is_active(buf_if.req_crossbar),                                                        \
        /*.buffer_outport_sel(buf_if.switch_outport),*/                                         \
        .packet_sent(buf_if.REN),                                                               \
        .outport_enabled(cb_if.enable),                                                         \
        .buffer_availability(CB.buffer_availability),                                           \
        .outport_selected_vc(CB.outport_vc)                                                     \
    );

module switch_tracker#(
    parameter int NUM_OUTPORTS,
    parameter int NUM_BUFFERS,
    parameter int NUM_VCS,
    parameter int BUFFER_SIZE,
    parameter int TOTAL_NODES,
    parameter node_id_t NODE
)(
    input logic clk,
    input logic nrst,
    // Buffers are not in idle state, used to calculate latency
    input logic [NUM_VCS*NUM_BUFFERS-1:0] not_idle,
    // Buffers are active, used to calculate how long it takes to send a packet
    // Interesting metrics are is_active/not_idle, cycle/word from is_active
    // and packet_sent (include nominative and actual)
    input logic [NUM_VCS*NUM_BUFFERS-1:0] is_active,
    // Packet sent from input buffer, used to calculate throughput
    // TODO: calculate actual throughput taking into account
    // head/tail/addr/crc flits
    input logic [NUM_VCS*NUM_BUFFERS-1:0] packet_sent,
    //
    // input logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] buffer_outport_sel,
    // Switch is allocated, but can't send due to low credit, used to measure
    // back pressure
    input logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] outport_enabled,
    input logic [NUM_OUTPORTS-1:0] [NUM_VCS-1:0] [$clog2(BUFFER_SIZE+1)-1:0] buffer_availability,
    input logic [NUM_OUTPORTS-1:0] [$clog2(NUM_VCS)-1:0] outport_selected_vc
);
    int v_latency [NUM_VCS*NUM_BUFFERS-1:0] [$];
    int v_active_time [NUM_VCS*NUM_BUFFERS-1:0] [$];
    int v_flits_sent [NUM_VCS*NUM_BUFFERS-1:0] [$];
    int latency [NUM_VCS*NUM_BUFFERS-1:0], active_time [NUM_VCS*NUM_BUFFERS-1:0];
    int num_flits_sent [NUM_VCS*NUM_BUFFERS-1:0], num_packets_sent [NUM_VCS*NUM_BUFFERS-1:0];
    int outport_total_len [NUM_OUTPORTS-1:0] [NUM_VCS-1:0];
    int outport_blocked_len [NUM_OUTPORTS-1:0] [NUM_VCS-1:0];
    logic [NUM_VCS*NUM_BUFFERS-1:0] not_idle_negedge;

    generate
        for (genvar i = 0; i < NUM_VCS*NUM_BUFFERS; i++) begin
            socetlib_counter #(
                .NBITS(32)
            ) LATENCY_COUNTER (
                .CLK(clk),
                .nRST(nrst),
                .clear(not_idle_negedge[i]),
                .count_enable(not_idle[i]),
                .overflow_val(-1),
                .count_out(latency[i]),
                .overflow_flag()
            );

            socetlib_counter #(
                .NBITS(32)
            ) ACTIVE_COUNTER (
                .CLK(clk),
                .nRST(nrst),
                .clear(not_idle_negedge[i]),
                .count_enable(is_active[i]),
                .overflow_val(-1),
                .count_out(active_time[i]),
                .overflow_flag()
            );

            socetlib_counter #(
                .NBITS(32)
            ) FLIT_COUNTER (
                .CLK(clk),
                .nRST(nrst),
                .clear(not_idle_negedge[i]),
                .count_enable(packet_sent[i]),
                .overflow_val(-1),
                .count_out(num_flits_sent[i]),
                .overflow_flag()
            );

            socetlib_counter #(
                .NBITS(32)
            ) PACKET_COUNTER (
                .CLK(clk),
                .nRST(nrst),
                .clear(1'b0),
                .count_enable(not_idle_negedge[i]),
                .overflow_val(-1),
                .count_out(num_packets_sent[i]),
                .overflow_flag()
            );

            socetlib_edge_detector #(
                .WIDTH(1)
            ) EDGE (
                .CLK(clk),
                .nRST(nrst),
                .signal(not_idle[i]),
                .pos_edge(),
                .neg_edge(not_idle_negedge[i])
            );
        end

        for (genvar i = 0; i < NUM_OUTPORTS; i++) begin
            for (genvar j = 0; j < NUM_VCS; j++) begin
                socetlib_counter #(
                    .NBITS(32)
                ) OUTPORT_TOTAL_COUNTER (
                    .CLK(clk),
                    .nRST(nrst),
                    .clear(0),
                    .count_enable(outport_enabled[i][j] && outport_selected_vc[i] == j),
                    .overflow_val(-1),
                    .count_out(outport_total_len[i][j]),
                    .overflow_flag()
                );

                socetlib_counter #(
                    .NBITS(32)
                ) OUTPORT_CREDIT_BLOCKED_COUNTER (
                    .CLK(clk),
                    .nRST(nrst),
                    .clear(0),
                    .count_enable(outport_enabled[i][j] && buffer_availability[i][j] <= BUFFER_SIZE/4 && outport_selected_vc[i] == j),
                    .overflow_val(-1),
                    .count_out(outport_blocked_len[i][j]),
                    .overflow_flag()
                );
            end
        end
    endgenerate

    always_ff @(posedge clk, negedge nrst) begin
        if (!nrst) begin
            for (int i = 0; i < NUM_VCS*NUM_BUFFERS; i++) begin
                v_latency[i] = {};
                v_active_time[i] = {};
                v_flits_sent[i] = {};
            end
        end else begin
            for (int i = 0; i < NUM_VCS*NUM_BUFFERS; i++) begin
                if (not_idle_negedge[i]) begin
                    v_latency[i].push_back(latency[i]);
                    v_active_time[i].push_back(active_time[i]);
                    v_flits_sent[i].push_back(num_flits_sent[i]);
                end
            end
        end
    end

    // Stupid function to create a file to get the system time
    function string get_localtime();
        int fd;
        string localtime;
    begin
        void'($system("date \"+%F_%T\" > ._localtime")); // temp file
        fd = $fopen("._localtime", "r");
        void'($fscanf(fd,"%s",localtime));
        $fclose(fd);
        void'($system("rm ._localtime")); // delete file
        return localtime;
    end
    endfunction

    function string node2string(input node_id_t node_id);
        string s;
    begin
        s = $sformatf("%0d", node_id);
        return s;
    end
    endfunction

    function real average_queue(input int q [$]);
    begin
        real avg;
        avg = 0;
        foreach (q[i]) begin
            avg += q[i];
        end
         return avg / q.size();
    end
    endfunction

    real avg_latency;
    real avg_active_time;
    real avg_flits_per_packet;
    real outport_blocked;
    final begin
        string localtime = get_localtime();
        string filename = {"./switch", node2string(NODE), "_perf", localtime, ".txt"};
        int fd = $fopen(filename, "w");
        if (fd != 0) begin
            $display("File %s was opened successfully : %0d", filename, fd);
        end else begin
            $display("File %s was NOT opened successfully : %0d", filename, fd);
            $stop();
        end

        for (int i = 0; i < NUM_VCS*NUM_BUFFERS; i++) begin
            $fwrite(fd, "(Switch %0d) Packets sent through buffer %0d: %0d\n", NODE, i, num_packets_sent[i]);

            avg_latency = average_queue(v_latency[i]);
            avg_active_time = average_queue(v_active_time[i]);
            avg_flits_per_packet = average_queue(v_flits_sent[i]);

            $fwrite(fd, "(Buffer %0d) avg latency: %f cycles\n", i, avg_latency);
            $fwrite(fd, "(Buffer %0d) avg active time: %f cycles\n", i, avg_active_time);
            $fwrite(fd, "(Buffer %0d) flits per packet: %f cycles\n", i, avg_flits_per_packet);
            $fwrite(fd, "(Buffer %0d) crossbar cycles per flit: %f cycles\n", i, avg_active_time / avg_flits_per_packet);
            $fwrite(fd, "(Buffer %0d) avg pipeline efficiency: %f%%\n", i, 100 *  (avg_latency - avg_active_time) / avg_latency);
        end

        for (int i = 0; i < NUM_OUTPORTS; i++) begin
            for (int j = 0; j < NUM_VCS; j++) begin
                outport_blocked = real'(outport_blocked_len[i][j]) / outport_total_len[i][j];
                $fwrite(fd, "(Outport %0d:%0d) avg outport credit constraint: %f%%\n", i, j, 100 * (1 - outport_blocked));
            end
        end

        $fclose(fd);
    end
endmodule
