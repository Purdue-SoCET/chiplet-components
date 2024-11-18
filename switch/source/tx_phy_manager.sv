`timescale 1ns / 10ps

module tx_phy_manager #() (
    input logic clk, n_rst,
    phy_manager_if.tx_phy phy_if,
    phy_manager_if.tx_switch switch_if
);

    flit_t flit, next_flit;

    always_ff @(posedge clk, negedge n_rst) begin
        if(!n_rst) begin
            flit <= '0;
        end
        else begin
            flit <= next_flit;
        end
    end

    always_comb begin //input flit logic
        if(phy_if.data_ready) next_flit = phy_if.flit;
        else next_flit = flit;
    end

    always_comb begin //8b10b encode
        // run 8b10b encode with {flit.vc, flit.id, flit.req, flit.payload}




    end

endmodule