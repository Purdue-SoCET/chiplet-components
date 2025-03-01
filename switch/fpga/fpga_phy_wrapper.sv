module fpga_phy_wrapper(
    input flit_t sw_if_out,
    input logic sw_if_data_ready_out,
    output flit_t sw_if_in,
    output logic sw_if_data_ready_in,
    uart_rx_if rx_if,
    uart_tx_if tx_if
); 
    import phy_types_pkg::*;

    flit_enc_t tx_flit_encoded;
    flit_t tx_flit;
    flit_enc_t rx_flit_encoded;
    flit_t rx_flit;

    genvar i;
    generate
        for (i = 0; i < 5; i++) begin : dec_8b10b_block
            dec_8b10b dec (
                .data_in(rx_flit_encoded[(i * 10)+:10]),
                .data_out(rx_flit[(i * 8)+:8])
            );
        end
        for (i = 0; i < 4; i++) begin : enc_8b10b_block
            enc_8b10b enc (
                .data_in(tx_flit[(i * 8)+:8]),
                .data_out(tx_flit_encoded[(i * 10)+:10])
            );
        end
    endgenerate

    always_comb begin
        sw_if_in = rx_flit;
        sw_if_data_ready_in = rx_if.done;
        tx_flit = sw_if_out;
        rx_flit_encoded = rx_if.data;
        tx_if.data = tx_flit_encoded;
        tx_if.start = sw_if_data_ready_out;
    end
endmodule
