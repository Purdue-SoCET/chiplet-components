

module socetlib_stack #(
    parameter type T = logic [7:0],
    parameter DEPTH = 8,
    parameter ADDR_BITS = $clog2(DEPTH)
)(
    input CLK,
    input nRST,
    input push,
    input pop,
    input clear,
    input T wdata,
    output logic empty,
    output logic full,
    output logic overflow,
    output logic underflow,
    output logic [ADDR_BITS:0] count,
    output T rdata
);

    generate
        if(DEPTH < 1 || (DEPTH & (DEPTH - 1)) != 0) begin
            $error("%m: DEPTH must be a power of 2 greater than 0");
        end

        if(ADDR_BITS != $clog2(DEPTH)) begin
            $error("%m: ADDR_BITS is an automatically computed value and should not be changed.\n");
        end
    endgenerate

    T [DEPTH-1:0] stack, stack_next;
    logic [ADDR_BITS:0] ptr, ptr_next; // Stack pointer has 1 extra bit for easy determination of count and full
    logic overflow_next, underflow_next;

    always_ff @(posedge CLK, negedge nRST) begin
        if(!nRST) begin
            stack <= '{default: '0};
            ptr <= '0;
            overflow <= 1'b0;
            underflow <= 1'b0;
        end else begin
            stack <= stack_next;
            ptr <= ptr_next;
            overflow <= overflow_next;
            underflow <= underflow_next;
        end
    end

    // ptr points to the next element to write, reads are from (ptr - 1) 
    always_comb begin
        stack_next = stack;
        ptr_next = ptr;
        overflow_next = overflow;
        underflow_next = underflow;

        if(clear) begin
            ptr_next = '0;
            overflow_next = 1'b0;
            underflow_next = 1'b0;
        end else begin
            overflow_next = (full && push);
            underflow_next = (empty && pop);
            if(push) begin
                stack_next[ptr] = wdata;
            end
            // Takes care of increment and decrement on push/pop respectively
            ptr_next = ptr + push - pop;
        end
    end


    assign rdata = stack[ptr - 1];
    assign count = ptr;

    assign empty = (count == 0);
    assign full = count[ADDR_BITS];

endmodule
