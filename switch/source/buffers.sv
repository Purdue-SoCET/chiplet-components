`timescale 1ns / 10ps

`include "chiplet_types_pkg.vh"
`include "buffers_if.vh"

module buffers #(
    parameter NUM_BUFFERS,
    parameter DEPTH// # of FIFO entries
)(
    input CLK,
    input nRST,
    buffers_if.buffs buf_if
);

    // Parameter checking
    //
    // Width can be any number of bits > 1, but depth must be a power-of-2 to accomodate addressing scheme
    // TODO: 
    generate
        if(DEPTH == 0 || (DEPTH & (DEPTH - 1)) != 0) begin
            $error("%m: DEPTH must be a power of 2 >= 1!");
        end
    endgenerate
    
    localparam int ADDR_BITS = $clog2(DEPTH);

    logic [NUM_BUFFERS-1:0] overrun_next, underrun_next;
    logic [NUM_BUFFERS-1:0] [ADDR_BITS-1:0] write_ptr, write_ptr_next, read_ptr, read_ptr_next;
    logic [NUM_BUFFERS-1:0] [$clog2(DEPTH+1)-1:0] count_next;
    flit_t [NUM_BUFFERS-1:0] [DEPTH-1:0] fifo, fifo_next;

    always_ff @(posedge CLK, negedge nRST) begin
        if(!nRST) begin
            fifo <= '{default: '0};
            write_ptr <= '0;
            read_ptr <= '0;
            buf_if.overrun <= 1'b0;
            buf_if.underrun <= 1'b0;
            buf_if.count <= '0;
        end else begin
            fifo <= fifo_next;
            write_ptr <= write_ptr_next;
            read_ptr <= read_ptr_next;
            buf_if.overrun <= overrun_next;
            buf_if.underrun <= underrun_next;
            buf_if.count <= count_next;
        end
    end
    int i, j;

    always_comb begin
        fifo_next = fifo;
        write_ptr_next = write_ptr;
        read_ptr_next = read_ptr;
        overrun_next = buf_if.overrun;
        underrun_next = buf_if.underrun;
        count_next = buf_if.count;

        for(i = 0; i < NUM_BUFFERS; i++) begin
            if(buf_if.clear[i]) begin
                // No need to actually reset FIFO data,
                // changing pointers/flags to "empty" state is OK
                write_ptr_next[i] = '0;
                read_ptr_next[i] = '0;
                overrun_next[i] = 1'b0;
                underrun_next[i] = 1'b0;
                count_next[i] = '0;
            end else begin
                if(buf_if.REN[i] && !buf_if.empty[i] && !(buf_if.full[i] && buf_if.WEN[i])) begin
                    read_ptr_next[i] = read_ptr[i] + 1;
                end else if(buf_if.REN[i] && buf_if.empty[i]) begin
                    underrun_next[i] = 1'b1;
                end

                if(buf_if.WEN[i] && !buf_if.full[i] && !(buf_if.empty[i] && buf_if.REN[i])) begin
                    write_ptr_next[i] = write_ptr[i] + 1;
                    fifo_next[i][write_ptr[i]] = wdata[i];
                end else if(WEN[i] && full[i]) begin
                    overrun_next[i] = 1'b1;
                end

                if (buf_if.count[i] == DEPTH) begin
                    count_next[i] = buf_if.count[i] - buf_if.REN[i] + (buf_if.REN[i] && buf_if.WEN[i]);
                end else if (buf_if.count[i] == 0) begin
                    count_next[i] = buf_if.count[i] + buf_if.WEN[i] - (buf_if.REN[i] && buf_if.WEN[i]);
                end else begin
                    count_next[i] = buf_if.count[i] + buf_if.WEN[i] - buf_if.REN[i];
                end
            end
        end
    end

    for(j = 0; j < NUM_BUFFERS; j++) begin
        assign buf_if.full[j] = buf_if.count[j] == DEPTH;
        assign buf_if.empty[j] = buf_if.count[j] == 0;
        assign buf_if.rdata[j] = fifo[j][read_ptr];
    end
endmodule