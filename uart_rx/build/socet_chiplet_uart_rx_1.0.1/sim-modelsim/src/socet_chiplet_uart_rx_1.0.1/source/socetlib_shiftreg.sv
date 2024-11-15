// Author:      Huy-Minh Tran
// Description: Flex Shift Register

module socetlib_shift_reg
#(
	parameter int NUM_BITS = 10,
	parameter bit SHIFT_MSB = 1, //1 is MSB, 0 is LSB
	parameter bit RESET_VAL = 1'b1 // reset value of the shift register (1'b1 or 1'b0)
)
(
	input clk,
	input nRST,
	input shift_enable,
	input serial_in,
	input parallel_load,
	input [NUM_BITS-1:0] parallel_in,
	output logic serial_out,
	output logic [NUM_BITS-1:0] parallel_out 
);

  	logic [NUM_BITS-1:0] q, n_q;

	assign parallel_out = q;
	assign serial_out = SHIFT_MSB ? q[NUM_BITS-1] : q[0];

	always_ff @(posedge clk, negedge nRST) begin
		if (nRST == 1'b0) begin
			q <= {NUM_BITS{RESET_VAL}};
		end
		else begin
			q <= n_q;
		end
	end

	always_comb begin
		n_q = q;
		if (shift_enable && SHIFT_MSB) begin
			n_q = {q[NUM_BITS-2:0], serial_in};
		end
		else if (shift_enable && ~SHIFT_MSB) begin
			n_q = {serial_in, q[NUM_BITS-1:1]};
		end
		// the parallel load should override any shift
		if (parallel_load) begin
		    n_q = parallel_in;
		end
	end
endmodule