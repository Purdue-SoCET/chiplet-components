// Creates a M input to N output crossbar switch
// This design synchronously updates output ports

`include "crossbar_if.sv"

module crossbar#(
    parameter int NUM_IN,
    parameter int NUM_OUT,
    parameter int NUM_VCS,
    parameter int BUFFER_SIZE
)(
    input logic clk, n_rst,
    crossbar_if.crossbar cb_if
);
    flit_t [NUM_OUT-1:0] next_out;
    logic [NUM_OUT-1:0] valid, next_valid;
    logic [NUM_OUT-1:0] [$clog2(NUM_VCS)-1:0] buffer_vc, outport_vc, next_outport_vc;
    logic [NUM_OUT-1:0] [NUM_VCS-1:0] [$clog2(BUFFER_SIZE+1)-1:0] buffer_availability, next_buffer_availability;

    // I have no idea how to clean this up
    function logic [NUM_OUT-1:0] [NUM_VCS-1:0] [$clog2(BUFFER_SIZE+1)-1:0] init_buffer_availability();
        for (int i = 0; i < NUM_OUT; i++) begin
            for (int j = 0; j < NUM_VCS; j++) begin
                init_buffer_availability[i][j] = BUFFER_SIZE[0+:$clog2(BUFFER_SIZE+1)];
            end
        end
    endfunction

    always_ff @(posedge clk, negedge n_rst) begin
        if (!n_rst) begin
            cb_if.out <= '0;
            valid <= '0;
            buffer_availability <= init_buffer_availability();
            outport_vc <= '0;
        end else begin
            cb_if.out <= next_out;
            valid <= next_valid;
            buffer_availability <= next_buffer_availability;
            outport_vc <= next_outport_vc;
            for (int i = 1; i < NUM_OUT; i++) begin
                for (int j = 0; j < NUM_VCS; j++) begin
                    if (buffer_availability[i][j] > BUFFER_SIZE) begin
                        $warning("Tracking for %d:%d is out of sync!", i, j);
                    end
                end
            end
        end
    end

    always_comb begin
        cb_if.in_pop = '0;
        next_valid = valid;
        next_buffer_availability = buffer_availability;
        next_outport_vc = outport_vc;

        for (int i = 0; i < NUM_OUT; i++) begin
            buffer_vc[i] = cb_if.buffer_vc[cb_if.sel[i][outport_vc[i]]];
            next_out[i] = cb_if.in[cb_if.sel[i][outport_vc[i]]];
            // Use the VC from the buffers since it could have been
            // speculatively allocated, so we can't rely on outport_vc being
            // accurate
            next_out[i].metadata.vc = outport_vc[i];

            if (cb_if.enable[i][outport_vc[i]] && !cb_if.empty[cb_if.sel[i][outport_vc[i]]] && buffer_availability[i][outport_vc[i]] > BUFFER_SIZE/4) begin
                if (cb_if.packet_sent[i]) begin
                    next_valid[i] = 0;
                    cb_if.in_pop[cb_if.sel[i][outport_vc[i]]] = 1;
                end else begin
                    next_valid[i] = 1;
                    cb_if.in_pop[cb_if.sel[i][outport_vc[i]]] = 0;
                end
            end else begin
                next_valid[i] = 0;
            end

            if (!next_valid[i]) begin
                if (i != 0 || !cb_if.enable[i][outport_vc[i]]) begin
                    next_outport_vc[i] = cb_if.enable[i][1];
                end
            end

            for (int j = 0; j < NUM_VCS; j++) begin
                /* verilator lint_off WIDTHTRUNC */
                if (i == 0) begin
                    next_buffer_availability[i][j] += cb_if.credit_granted[i][j];
                end else begin
                    next_buffer_availability[i][j] += cb_if.credit_granted[i][j] * 3*BUFFER_SIZE/4;
                end
                next_buffer_availability[i][j] -= cb_if.packet_sent[i] && j == outport_vc[i];
                /* verilator lint_on WIDTHTRUNC */
            end

            cb_if.valid[i] = valid[i] && cb_if.enable[i][outport_vc[i]];
        end
    end
endmodule
