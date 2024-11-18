`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"

module rx_phy_manager #() (
    input logic clk, n_rst,
    phy_manager_if.rx_switch switch_if
    phy_manager_if.rx_phy phy_if
);

    import chiplet_types_pkg::*;

    flit_t flit;
    logic [39:0] decode_output;
    logic [49:0] enc_flit, next_enc_flit, prev_flit;
    format_e format;
    pkt_id_t curr_id, next_id;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            enc_flit <= '0;
            prev_flit <= '0;
            curr_id <=
        end
        else begin
            enc_flit <= next_enc_flit;
            prev_flit <= enc_flit;
            curr_id <= next_id;
        end
    end

    always_comb begin //input flit logic
        if(phy_if.data_ready) next_enc_flit = phy_if.encoded_flit;
        else next_enc_flit = enc_flit;
    end


    always_comb begin //8b10b decode
        //run 8b10b with enc_flit output to flit


        flit = flit_t'(decode_output);
        next_id = flit.id;
    end

    always_comb begin //CRC checker
        if(curr_id != next_id) begin
            // run CRC check with prev_flit
        end

    end
endmodule


    // always_comb begin //format check
    //     if(curr_id != next_id) begin
    //         format = format_e'(flit.payload[31:28]);
    //     end
    //     else format = format;
    //     if(format == FMT_MSG) begin

    //     end

    // end
