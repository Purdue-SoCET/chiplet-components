`timescale 1ns / 10ps

module tile #(
    parameter NUM_LINKS,
    parameter BUFFER_SIZE = 8,
    parameter PORT_COUNT = 5,
    parameter UART_FREQ = 50_000_000,
    parameter UART_BAUD_RATE = 9600
) (
    input clk, n_rst,
    input logic [NUM_LINKS-1:0] [PORT_COUNT-1:0] uart_rx,
    output logic [NUM_LINKS-1:0] [PORT_COUNT-1:0] uart_tx,
    bus_protocol_if.peripheral_vital bus_if
);
    parameter NUM_VCS = 2;

    switch_if #(
        .NUM_OUTPORTS(NUM_LINKS + 1),
        .NUM_BUFFERS(NUM_LINKS + 1),
        .NUM_VCS(NUM_VCS)
    ) sw_if ();

    // Physical layer
    genvar i;
    generate
        for (i = 0; i < NUM_LINKS; i++) begin : g_phy_layer
            uart_rx_if #(
                .PORTCOUNT(PORT_COUNT)
            ) rx_if();
            uart_tx_if #(
                .PORTCOUNT(PORT_COUNT)
            ) tx_if();

            assign rx_if.uart_in = uart_rx[i];
            assign uart_tx[i] = tx_if.uart_out;

            always_comb begin
                tx_if.data = end_if.data_out_tx;
                tx_if.comma_sel = end_if.comma_sel_tx_out;
                tx_if.start = end_if.start_out_tx;
            end

            uart_baud #(
                .PORTCOUNT(PORT_COUNT),
                .FREQUENCY(UART_FREQ),
                .EXPECTED_BAUD_RATE(UART_BAUD_RATE)
            ) uart (
                .CLK(clk),
                .nRST(n_rst),
                .rx_if(rx_if),
                .tx_if(tx_if)
            );

            // Upper physical layer
            endnode_if end_if();
            endnode #(
                .PORTCOUNT(PORT_COUNT)
            ) endnode(
                .CLK(clk),
                .nRST(n_rst),
                .end_if(end_if)
            );

            always_comb begin
                end_if.enc_flit_rx = rx_if.data;
                end_if.done_in_rx = rx_if.done;
                end_if.comma_length_sel_in_rx = rx_if.comma_sel;
                end_if.err_in_rx = rx_if.rx_err;
                end_if.start_tx = sw_if.data_ready_out[i + 1];
                end_if.flit_tx = sw_if.out[i + 1];
                end_if.done_tx = tx_if.done;
                end_if.send_next_flit_tx = sw_if.data_ready_out[i + 1] /* TODO */;
                end_if.grtcred_tx = sw_if.buffer_available[i + 1];
                sw_if.packet_sent[i + 1] = end_if.get_data;
                sw_if.data_ready_in[i + 1] = end_if.done_rx;
                sw_if.in[i + 1] = end_if.flit_rx;
                sw_if.credit_granted[i + 1] = end_if.grtcred_rx;
            end
        end
    endgenerate

    // Data link layer
    switch #(
        .NUM_OUTPORTS(NUM_LINKS + 1),
        .NUM_BUFFERS(NUM_LINKS + 1),
        .NUM_VCS(NUM_VCS),
        .BUFFER_SIZE(BUFFER_SIZE),
        .TOTAL_NODES(4)
    ) switch (
        .clk(clk),
        .n_rst(n_rst),
        .sw_if(sw_if)
    );

    // Upper data link layer
    endpoint_if #(
        .NUM_VCS(2)
    ) endpoint_if();

    always_comb begin
        endpoint_if.out = sw_if.out[0];
        endpoint_if.buffer_available = sw_if.buffer_available[0];
        endpoint_if.data_ready_out = sw_if.data_ready_out[0];
        endpoint_if.node_id = sw_if.node_id;
        sw_if.in[0] = endpoint_if.in;
        sw_if.credit_granted[0] = endpoint_if.credit_granted;
        sw_if.data_ready_in[0] = endpoint_if.data_ready_in;
        sw_if.packet_sent[0] = endpoint_if.packet_sent;
    end

    endpoint #(
        .NUM_MSGS(4),
        .DEPTH(BUFFER_SIZE)
    ) endpoint1 (
        .clk(clk),
        .n_rst(n_rst),
        .endpoint_if(endpoint_if),
        .bus_if(bus_if)
    );
endmodule
