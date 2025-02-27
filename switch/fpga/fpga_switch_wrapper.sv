module fpga_switch_wrapper(
    input logic CLOCK_50,
    input logic [3:0] KEY,
    output logic [31:0] GPIO
);
    import chiplet_types_pkg::*;
    import phy_types_pkg::*;

    localparam NUM_SWITCHES=2;
    localparam NUM_LINKS=1;
    localparam BUFFER_SIZE=8;

    logic [NUM_SWITCHES-1:0] [NUM_LINKS-1:0] uart_rx;
    logic [NUM_SWITCHES-1:0] [NUM_LINKS-1:0] uart_tx;
    logic [31:0] int_gpio, int_gpio_out;

    assign uart_rx[0] = uart_tx[1];
    assign uart_rx[1] = uart_tx[0];
    assign int_gpio_out[0] = uart_tx[0];
    assign int_gpio_out[1] = uart_tx[1];

    genvar i, j;
    generate
        for (i = 0; i < NUM_SWITCHES; i++) begin : g_switch
            switch_if #(
                .NUM_OUTPORTS(NUM_LINKS + 1),
                .NUM_BUFFERS(NUM_LINKS + 1),
                .NUM_VCS(2)
            ) sw_if();

            for (j = 0; j < NUM_LINKS; j++) begin : g_uart
                uart_tx_if #(
                    .PORTCOUNT(1)
                ) tx_if();
                uart_rx_if #(
                    .PORTCOUNT(1)
                ) rx_if();

                assign rx_if.uart_in = uart_rx[i][j];
                assign uart_tx[i][j] = tx_if.uart_out;

                always_comb begin
                    // tx_if.data = sw_if.out[i + 1];
                    tx_if.comma_sel = SELECT_COMMA_DATA;
                    tx_if.start = sw_if.data_ready_out[j + 1];
                    sw_if.data_ready_in[j + 1] = rx_if.done;
                    // sw_if.in[i + 1] = rx_if.data;
                end

                uart #(
                    .PORTCOUNT(1),
                    .EXPECTED_BAUD_RATE(9600)
                ) uart (
                    .CLK(CLOCK_50),
                    .nRST(KEY[1]),
                    .rx_if(rx_if),
                    .tx_if(tx_if)
                );
            end

            flit_t [NUM_LINKS+1-1:0] out /* synthesis syn_noprune */;

            always_ff @(posedge CLOCK_50, negedge KEY[0]) begin
                if (!KEY[0]) begin
                    out <= 0;
                end else begin
                    out <= sw_if.out;
                end
            end

            bus_protocol_if bus_if();

            assign bus_if.wen = int_gpio[3];
            assign bus_if.ren = int_gpio[4];

            switch #(
                .NUM_OUTPORTS(NUM_LINKS + 1),
                .NUM_BUFFERS(NUM_LINKS + 1),
                .NUM_VCS(2),
                .BUFFER_SIZE(BUFFER_SIZE),
                .TOTAL_NODES(2)
            ) switch (
                .clk(CLOCK_50),
                .n_rst(KEY[0]),
                .sw_if(sw_if)
            );

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
                .clk(CLOCK_50),
                .n_rst(KEY[0]),
                .endpoint_if(endpoint_if),
                .bus_if(bus_if)
            );
        end
    endgenerate

    generate
        for (i = 0; i < 32; i++) begin : bidir_gen
            assign GPIO[i] = i > 2 ? 1'bZ : int_gpio_out[i];
        end
    endgenerate

    always_ff @(posedge CLOCK_50) begin
        int_gpio <= GPIO;
    end
endmodule
