`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "switch_if.vh"
`include "endpoint_if.sv"

module endpoint #(
    parameter NUM_MSGS=4,
    parameter DEPTH
) (
    input logic clk, n_rst,
    output logic packet_recv,
    endpoint_if endpoint_if,
    bus_protocol_if.peripheral_vital bus_if
);
    import chiplet_types_pkg::*;

    localparam TX_WRITE_ADDR = 32'h0000;
    localparam TX_SEND_ADDR = 32'h0004;
    localparam RX_READY_ADDR = 32'h1000;
    localparam RX_PAYLOAD_ADDR = 32'h1004;
    localparam RX_METADATA_ADDR = 32'h1008;
    localparam CONFIG_DONE_ADDR = 32'h100C;

    logic rx_fifo_ren, rx_fifo_wen, rx_fifo_empty, rx_fifo_full;
    flit_t rx_fifo_rdata;

    tx_fsm_if #(.NUM_MSGS(NUM_MSGS)) tx_fsm_if();

    socetlib_fifo #(
        .WIDTH($bits(flit_t)),
        .DEPTH(4)
    ) rx_fifo (
        .CLK(clk),
        .nRST(n_rst),
        .WEN(rx_fifo_wen),
        .REN(rx_fifo_ren),
        .wdata(endpoint_if.out),
        .clear(1'b0),
        .full(rx_fifo_full),
        .empty(rx_fifo_empty),
        .underrun(),
        .overrun(),
        .count(),
        .rdata(rx_fifo_rdata)
    );

    tx_fsm #(
        .NUM_MSGS(NUM_MSGS),
        .TX_SEND_ADDR(TX_SEND_ADDR),
        .DEPTH(DEPTH)
    ) tx_fsm(
        .clk(clk),
        .n_rst(n_rst),
        .tx_if(tx_fsm_if),
        .endpoint_if(endpoint_if)
    );

    always_comb begin
        rx_fifo_wen = 0;
        endpoint_if.packet_sent = 0;
        endpoint_if.credit_granted = 0;

        if (endpoint_if.data_ready_out && !rx_fifo_full) begin
            rx_fifo_wen = 1;
            endpoint_if.packet_sent = 1;
            endpoint_if.credit_granted[endpoint_if.out.metadata.vc] = 1;
        end
    end

    always_comb begin
        bus_if.rdata = 32'hBAD1BAD1;
        bus_if.error = 0;
        bus_if.request_stall = 0;
        tx_fsm_if.wen = 0;
        tx_fsm_if.start = 0;
        tx_fsm_if.wdata = bus_if.wdata;
        tx_fsm_if.node_id = endpoint_if.node_id;
        rx_fifo_ren = 0;

        // TX cache
        if (bus_if.addr == TX_SEND_ADDR) begin
            bus_if.rdata = tx_fsm_if.sending;
            if (bus_if.wen && !tx_fsm_if.sending && bus_if.wdata < NUM_MSGS) begin
                tx_fsm_if.start = 1;
            end
        end else if (bus_if.wen && bus_if.addr == TX_WRITE_ADDR) begin
            if (tx_fsm_if.sending) begin
                if (!tx_fsm_if.busy) begin
                    tx_fsm_if.wen = 1;
                end else begin
                    bus_if.request_stall = 1;
                end
            end else begin
                bus_if.error = 1;
            end
        // RX cache
        end else if (bus_if.ren && bus_if.addr == RX_READY_ADDR) begin
            bus_if.rdata = !rx_fifo_empty;
        end else if (bus_if.ren && bus_if.addr == RX_PAYLOAD_ADDR) begin
            if (!rx_fifo_empty) begin
                bus_if.rdata = rx_fifo_rdata.payload;
                rx_fifo_ren = 1;
            end else begin
                bus_if.error = 1;
            end
        end else if (bus_if.ren && bus_if.addr == RX_METADATA_ADDR) begin
            if (!rx_fifo_empty) begin
                bus_if.rdata = rx_fifo_rdata.metadata;
            end else begin
                bus_if.error = 1;
            end
        end else if (bus_if.addr == CONFIG_DONE_ADDR) begin
            bus_if.rdata = {31'd0, endpoint_if.config_done};
        end else if (bus_if.wen || bus_if.ren) begin
            bus_if.error = 1;
        end
    end
endmodule
