module fpga_phy_wrapper #(
    parameter int NUM_LINKS
) (
    switch_if.switch sw_if,
    uart_rx_if.rx[NUM_LINKS-1:0] rx_if,
    uart_tx_if.tx[NUM_LINKS-1:0] tx_if
); 
    genvar i;
    genvar j;
    generate
        for (i = 0; i < NUM_LINKS; i= i + 1)begin
            wrap_dec_8b_10b_if dec_if();
            wrap_enc_8b_10b_if enc_if();

            for (j = 0; j < 5; j= j + 1) begin : enc_8b10b_block
                dec_8b10b dec (
                    .data_in(dec_if.enc_flit[(i * 10)+:10]),
                    .data_out(dec_if.flit[(i * 8)+:8]),
                );
            end
            for (j = 0; j < PORTCOUNT; j= j +1) begin : enc_8b10b_block
                enc_8b10b enc (
                    .data_in(enc_if.flit[(i * 8)+:8]),
                    .data_out(enc_if.flit_out[(i * 10)+:10])
                );
            end
            sw_if.in[i+1] = dec_if.flit;
            sw_if.data_ready_in[i+1] = dec_if.done_out;
            enc_if.start = sw_if.data_ready_out[i+1];
            enc_if.flit = sw_if.out[i+1];
            dec_if.enc_flit = rx_if[i].data;
            dec_if.done = rx_if[i].done;
            tx_if[i].data = enc_if.flit_out;
            tx_if[i].start = enc_if.start_out;
        end
    endgenerate
endmodule