module message_table#(
    parameter NUM_MSGS=4
)(
    input logic clk,
    input logic n_rst,
    message_table_if.msg_table msg_if
);
    typedef enum logic [2:0] {UNALLOC, ALLOC, PENDING, SEND, WAIT_FOR_RESP} msg_state_e;

    msg_state_e [NUM_MSGS-1:0] pkts, next_pkts;

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            pkts <= {NUM_MSGS{UNALLOC}};
        end else begin
            pkts <= next_pkts;
        end
    end

    // Next state logic
    always_comb begin
        next_pkts = pkts;
        for (int i = 0; i < NUM_MSGS; i++) begin
            if (pkts[i] == UNALLOC && msg_if.trigger_send[i]) begin
                next_pkts[i] = ALLOC;
            end
        end
    end

    // Output logic
    always_comb begin
    end
endmodule
