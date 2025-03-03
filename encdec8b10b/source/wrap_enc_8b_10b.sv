`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "phy_types_pkg.vh"

module wrap_enc_8b_10b #(
    parameter PORTCOUNT = 5
) (
    input logic CLK, nRST,
    wrap_enc_8b_10b_if.enc enc_if
);
    import phy_types_pkg::*;
    import chiplet_types_pkg::*;

    flit_enc_t flit_norm, n_flit;
    comma_length_sel_t n_comma_length_sel_out;
    logic start_n;
    always_ff @(posedge CLK, negedge nRST) begin
        if (~nRST) begin
            enc_if.start_out <= '0;
            enc_if.flit_out <= '0;
            enc_if.comma_length_sel_out <= SELECT_COMMA_1_FLIT;
        end
        else begin
            enc_if.start_out <= start_n;
            enc_if.flit_out <= n_flit;
            enc_if.comma_length_sel_out <= n_comma_length_sel_out;
        end
    end

    genvar i;
    generate
    for (i = 0; i < PORTCOUNT; i= i +1) begin : enc_8b10b_block
        enc_8b10b enc (
            .data_in(enc_if.flit[i*8+:8]),
            .data_out(flit_norm[i*10+:10]));
    end
    endgenerate

    //comma selection
    always_comb begin
        start_n = '0;
        n_flit = '0;
        n_comma_length_sel_out = SELECT_COMMA_1_FLIT;
        if (enc_if.start) begin
            start_n = '1;
            case (enc_if.comma_sel)
                START_PACKET_SEL: begin
                    n_flit =  {START_COMMA, {40{1'b1}}};
                    n_comma_length_sel_out = SELECT_COMMA_1_FLIT;
                end
                END_PACKET_SEL:  begin
                    n_flit =  {END_COMMA, {40{1'b1}}};
                    n_comma_length_sel_out = SELECT_COMMA_1_FLIT;
                    end
                GRTCRED0_SEL: begin
                    n_flit = {GRTCRED0_COMMA,{40{1'b1}}};
                    n_comma_length_sel_out = SELECT_COMMA_1_FLIT;
                    end
                GRTCRED1_SEL: begin
                    n_flit = {GRTCRED1_COMMA, {40{1'b1}}};
                    n_comma_length_sel_out = SELECT_COMMA_1_FLIT;
                end
                ACK_SEL: begin
                    n_flit = {ACK_COMMA,flit_norm.meta_data, {30{1'b1}}};
                    n_comma_length_sel_out = SELECT_COMMA_2_FLIT;
                end
                DATA_SEL:  begin
                    n_flit = flit_norm;
                    n_comma_length_sel_out = SELECT_COMMA_DATA;
                    end
                default: begin end
            endcase
        end
    end
endmodule
