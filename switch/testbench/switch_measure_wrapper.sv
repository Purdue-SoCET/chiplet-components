`include "switch_tracker.sv"

`define CONNECT(to, from, in_port, out_port)                                                    \
    assign to.in[in_port] = from.out[out_port];                                                 \
    assign to.data_ready_in[in_port] = from.data_ready_out[out_port];                           \
    assign to.credit_granted[in_port] = from.buffer_available[out_port];                        \
    assign to.packet_sent[in_port] = from.data_ready_in[out_port] & to.data_ready_out[in_port];

`define CONNECT_TO_TOP(to, idx)                                                 \
    assign to.in[0] = in_flit[idx];                                             \
    assign to.data_ready_in[0] = data_ready_in[idx];                            \
    assign to.credit_granted[0] = to.packet_sent[0] << to.out[0].metadata.vc;   \
    assign to.packet_sent[0] = data_ready_out[idx] & packet_sent[idx];          \
    assign out[idx] = to.out[0];                                                \
    assign data_ready_out[idx] = to.data_ready_out[0];                          \
    assign credit_granted[idx] = to.credit_granted[0][0];                       \
    assign credit_granted[idx] = to.credit_granted[0][0];                       \
    assign buffer_available[idx] = to.buffer_available[0][0];                   \
    assign buffer_available[NUM_NODES + idx] = to.buffer_available[0][1];

parameter NUM_NODES = 4;

module switch_wrapper(
    input logic clk, nrst,
    // Flit sent in from endpoint
    input flit_t in_flit [NUM_NODES-1:0],
    input logic data_ready_in [NUM_NODES-1:0],
    input logic packet_sent [NUM_NODES-1:0],
    // Flit received by endpoint
    output flit_t out [NUM_NODES-1:0],
    output logic data_ready_out [NUM_NODES-1:0],
    output logic buffer_available [NUM_NODES*2-1:0],
    output logic credit_granted [NUM_NODES-1:0]
);
    localparam BUFFER_SIZE = 8;
    localparam NUM_BUFFERS = 3;
    localparam NUM_OUTPORTS = 3;
    localparam NUM_VCS = 2;

    // Topology for testing
    // ┌─────────────┐       ┌─────────────┐
    // │             │       │             │
    // │             ┼──────►┤             │
    // │      1      │       │      2      │
    // │             ├◄──────┼             │
    // │             │       │             │
    // └─────┬─┬─────┘       └─────┬─┬─────┘
    //       │ ▲                   │ ▲
    //       │ │                   │ │
    //       ▼ │                   ▼ │
    // ┌─────┴─┴─────┐       ┌─────┴─┴─────┐
    // │             │       │             │
    // │             ┼──────►┤             │
    // │      3      │       │      4      │
    // │             ├◄──────┼             │
    // │             │       │             │
    // └─────────────┘       └─────────────┘
    //
    // In ports for 1: {endpoint, 2, 3}
    // Out ports for 1: {endpoint, 2, 3}
    // In ports for 2: {endpoint, 1, 4}
    // Out ports for 2: {endpoint, 1, 4}
    // In ports for 3: {endpoint, 1, 4}
    // Out ports for 3: {endpoint, 1, 4}
    // In ports for 4: {endpoint, 2, 3}
    // Out ports for 4: {endpoint, 2, 3}

    switch_if #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) sw_if1 ();

    switch #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE),
        .TOTAL_NODES(4)
    ) switch1 (
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if1),
        .packet_recv()
    );

    `CONNECT_TO_TOP(sw_if1, 0)
    `CONNECT(sw_if1, sw_if2, 1, 1)
    `CONNECT(sw_if1, sw_if3, 2, 1)

    `BIND_SWITCH_TRACKER

    // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-

    switch_if #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) sw_if2 ();

    switch #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_BUFFERS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE),
        .TOTAL_NODES(4)
    ) switch2 (
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if2),
        .packet_recv()
    );

    `CONNECT_TO_TOP(sw_if2, 1)
    `CONNECT(sw_if2, sw_if1, 1, 1)
    `CONNECT(sw_if2, sw_if4, 2, 1)

    // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-

    switch_if #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) sw_if3 ();

    switch #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE),
        .TOTAL_NODES(4)
    ) switch3 (
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if3),
        .packet_recv()
    );

    `CONNECT_TO_TOP(sw_if3, 2)
    `CONNECT(sw_if3, sw_if1, 1, 2)
    `CONNECT(sw_if3, sw_if4, 2, 2)

    // =-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-==-=-=-=-=-=-=-=-=-=-

    switch_if #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS)
    ) sw_if4 ();

    switch #(
        .NUM_OUTPORTS(NUM_OUTPORTS),
        .NUM_BUFFERS(NUM_OUTPORTS),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE),
        .TOTAL_NODES(4)
    ) switch4 (
        .clk(clk),
        .n_rst(nrst),
        .sw_if(sw_if4),
        .packet_recv()
    );

    `CONNECT_TO_TOP(sw_if4, 3)
    `CONNECT(sw_if4, sw_if2, 1, 2)
    `CONNECT(sw_if4, sw_if3, 2, 2)
endmodule
