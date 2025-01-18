`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "buffers_if.sv"

module buffers #(
    parameter NUM_BUFFERS,
    parameter NUM_OUTPORTS,
    parameter DEPTH // # of FIFO entries
)(
    input CLK,
    input nRST,
    buffers_if.buffs buf_if
);
    import chiplet_types_pkg::*;

    typedef enum logic [2:0] {
        IDLE,
        ROUTING,
        VC_ALLOCATION,
        SWITCH_ALLOCATION,
        ACTIVE
    } state_t;

    typedef struct packed {
        state_t state;
        logic [$clog2(NUM_OUTPORTS)-1:0] outport_sel;
        logic vc;
    } state_table_t;

    localparam state_table_t DEFAULT_TABLE = '{
        state: IDLE,
        outport_sel: 0,
        vc: 0
    };

    logic [NUM_BUFFERS-1:0] overrun, underrun, overflow, waterfall_overflow;
    logic [NUM_BUFFERS-1:0] [PKT_LENGTH_WIDTH-1:0] overflow_val, next_overflow_val, count_out;
    logic [NUM_BUFFERS-1:0] [$clog2(DEPTH+1)-1:0] count;
    state_table_t [NUM_BUFFERS-1:0] state_table, next_state_table;

    always_ff @(posedge CLK, negedge nRST) begin
        if (!nRST) begin
            overflow_val <= '1;
            state_table <= {NUM_BUFFERS{DEFAULT_TABLE}};
        end else begin
            overflow_val <= next_overflow_val;
            state_table <= next_state_table;
        end
    end

    genvar i;
    generate
        for (i = 0; i < NUM_BUFFERS; i++) begin
            socetlib_fifo #(
                .T(flit_t),
                .DEPTH(DEPTH)
            ) FIFO (
                .CLK(CLK),
                .nRST(nRST),
                .WEN(buf_if.WEN[i]),
                .REN(buf_if.REN[i] && buf_if.req_crossbar[i] && !overflow[i]),
                .clear(1'b0),
                .wdata(buf_if.wdata[i]),
                .full(),
                .empty(),
                .overrun(overrun[i]),
                .underrun(underrun[i]),
                .count(count[i]),
                .rdata(buf_if.rdata[i])
            );

            assign buf_if.available[i] = waterfall_overflow[i];

            socetlib_counter #(
                .NBITS(PKT_LENGTH_WIDTH)
            ) PACKET_COUNTER (
                .CLK(CLK),
                .nRST(nRST),
                .clear(state_table[i].state == SWITCH_ALLOCATION),
                .count_enable(buf_if.REN[i]),
                .overflow_val(overflow_val[i]),
                .count_out(count_out[i]),
                .overflow_flag(overflow[i])
            );

            socetlib_counter #(
                .NBITS(PKT_LENGTH_WIDTH)
            ) WATERFALL_COUNTER (
                .CLK(CLK),
                .nRST(nRST),
                .clear(waterfall_overflow[i]),
                .count_enable(buf_if.REN[i]),
                .overflow_val(3*DEPTH/4),
                .count_out(),
                .overflow_flag(waterfall_overflow[i])
            );
        end
    endgenerate

    always_ff @(posedge CLK) begin
        for (int i = 0; i < NUM_BUFFERS; i++) begin
            if (overrun[i]) begin
                $warning("WARNING: buffer %d is overrun!", i);
            end else if (underrun[i]) begin
                $warning("WARNING: buffer %d is underrun!", i);
            end
        end
    end

    always_comb begin
        buf_if.req_routing = '0;
        buf_if.req_vc = '0;
        buf_if.req_switch = '0;
        next_overflow_val = overflow_val;
        next_state_table = state_table;

        for (int i = 0; i < NUM_BUFFERS; i++) begin
            casez (state_table[i].state)
                IDLE : begin
                    // Head flit condition
                    if (buf_if.WEN[i] || count[i] > 0) begin
                        next_state_table[i].state = ROUTING;
                    end
                end
                ROUTING : begin
                    if (buf_if.routing_granted[i]) begin
                        next_state_table[i].outport_sel = buf_if.routing_outport;
                        next_state_table[i].state = VC_ALLOCATION;
                    end
                end
                VC_ALLOCATION : begin
                    if (buf_if.vc_granted[i]) begin
                        next_state_table[i].vc = buf_if.vc_selection;
                        next_state_table[i].state = SWITCH_ALLOCATION;
                    end
                end
                SWITCH_ALLOCATION : begin
                    if (buf_if.switch_granted[i]) begin
                        next_state_table[i].state = ACTIVE;
                        next_overflow_val[i] = expected_num_flits(buf_if.rdata[i].payload);
                    end
                end
                ACTIVE : begin
                    if (buf_if.REN[i] && count_out[i] + 1 == overflow_val[i]) begin
                        next_state_table[i].outport_sel = 0;
                        next_state_table[i].vc = 0;
                        next_state_table[i].state = IDLE;
                        next_overflow_val[i] = '1;
                    end
                end
                default : begin end
            endcase

            buf_if.req_routing[i] = state_table[i].state == ROUTING;
            buf_if.req_vc[i] = state_table[i].state == VC_ALLOCATION;
            buf_if.req_switch[i] = state_table[i].state == SWITCH_ALLOCATION;
            buf_if.req_crossbar[i] = state_table[i].state == ACTIVE;
            buf_if.switch_outport[i] = state_table[i].outport_sel;
            buf_if.final_vc[i] = state_table[i].vc;
        end
    end
endmodule
