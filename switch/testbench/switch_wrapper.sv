module switch_wrapper(
    input logic clk, nrst,
    // Flit sent in from endpoint
    input flit_t in_flit [3:0],
    input logic data_ready_in [3:0],
    input logic packet_sent [3:0],
    // Flit received by endpoint
    output flit_t out [3:0],
    output logic data_ready_out [3:0],
    output logic buffer_available [3:0],
    output logic credit_granted [3:0]
);
    switch_if #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2)
    ) sw_if1 ();

    switch #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2),
        .BUFFER_SIZE(8),
        .TOTAL_NODES(4),
        .NODE(1) // TODO: This should be configurable
    ) switch1 (
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if1)
    );

    assign sw_if1.in = {sw_if4.out[1], in_flit[0]};
    assign sw_if1.data_ready_in = {sw_if4.data_ready_out[1], data_ready_in[0]};
    assign sw_if1.credit_granted = sw_if1.packet_sent;
    assign sw_if1.packet_sent = {sw_if3.data_ready_in[1] & sw_if1.data_ready_out[1], data_ready_out[0] & data_ready_in[0]};

    // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-

    switch_if #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2)
    ) sw_if2 ();

    switch #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(2),
        .NUM_VCS(2),
        .BUFFER_SIZE(8),
        .TOTAL_NODES(4),
        .NODE(2) // TODO: This should be configurable
    ) switch2 (
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if2)
    );

    assign sw_if2.in = {sw_if4.out[2], in_flit[1]};
    assign sw_if2.data_ready_in = {sw_if4.data_ready_out[2], data_ready_in[1]};
    assign sw_if2.credit_granted = sw_if2.packet_sent;
    assign sw_if2.packet_sent = {sw_if3.data_ready_in[1] & sw_if2.data_ready_out[1], data_ready_out[1] & data_ready_in[1]};

    // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-

    switch_if #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(3),
        .NUM_VCS(2)
    ) sw_if3 ();

    switch #(
        .NUM_OUTPORTS(2),
        .NUM_BUFFERS(3),
        .NUM_VCS(2),
        .BUFFER_SIZE(8),
        .TOTAL_NODES(4),
        .NODE(3) // TODO: This should be configurable
    ) switch3 (
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if3)
    );

    assign sw_if3.in = {sw_if2.out[1], sw_if1.out[1], in_flit[2]};
    assign sw_if3.data_ready_in = {sw_if2.data_ready_out[1], sw_if1.data_ready_out[1], data_ready_in[2]};
    assign sw_if3.credit_granted = sw_if3.packet_sent;
    assign sw_if3.packet_sent = {sw_if4.data_ready_in[1] & sw_if3.data_ready_out[1], data_ready_out[2] & data_ready_in[2]};

    // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-

    switch_if #(
        .NUM_OUTPORTS(3),
        .NUM_BUFFERS(2),
        .NUM_VCS(2)
    ) sw_if4 ();

    switch #(
        .NUM_OUTPORTS(3),
        .NUM_BUFFERS(2),
        .NUM_VCS(2),
        .BUFFER_SIZE(8),
        .TOTAL_NODES(4),
        .NODE(4) // TODO: This should be configurable
    ) switch4 (
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if4)
    );

    assign sw_if4.in = {sw_if3.out[1], in_flit[3]};
    assign sw_if4.data_ready_in = {sw_if3.data_ready_out[1], data_ready_in[3]};
    assign sw_if4.credit_granted = sw_if4.packet_sent;
    assign sw_if4.packet_sent = {sw_if2.data_ready_in[1] & sw_if4.data_ready_out[2], sw_if1.data_ready_in[1] & sw_if4.data_ready_out[1], data_ready_out[3] & data_ready_in[3]};

    assign out = {sw_if4.out[0], sw_if3.out[0], sw_if2.out[0], sw_if1.out[0]};
    assign data_ready_out = {sw_if4.data_ready_out[0], sw_if3.data_ready_out[0], sw_if2.data_ready_out[0], sw_if1.data_ready_out[0]};
    assign buffer_available = {sw_if4.buffer_available[0][0], sw_if3.buffer_available[0][0], sw_if2.buffer_available[0][0], sw_if1.buffer_available[0][0]};
    assign credit_granted = {sw_if4.credit_granted[0][0], sw_if3.credit_granted[0][0], sw_if2.credit_granted[0][0], sw_if1.credit_granted[0][0]};
endmodule
