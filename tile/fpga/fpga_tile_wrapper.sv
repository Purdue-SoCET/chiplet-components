module fpga_tile_wrapper(
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
            bus_protocol_if bus_if();

            if (i == 0) begin
                fpga_endpoint_uart_fsm endpoint_uart_fsm (
                    .clk(CLOCK_50),
                    .n_rst(KEY[0]),
                    .serial_in(int_gpio[0]),
                    .bus_if(bus_if)
                );
            end

            tile #(
                .NUM_LINKS(NUM_LINKS),
                .BUFFER_SIZE(BUFFER_SIZE),
                .PORT_COUNT(1)
            ) TILE (
                .clk(CLOCK_50),
                .n_rst(KEY[0]),
                .uart_rx(uart_rx[i]),
                .uart_tx(uart_tx[i]),
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
