// Author:      Huy-Minh Tran
// Description: Flex Shift Register
`include "sr_if.svh"
module socetlib_shift_reg
#(
	parameter NUM_BITS = 4,
	parameter SHIFT_MSB = 1 //1 is MSB, 0 is LSB
)
(	
	sr_if sif
/*	input wire clk,
	input wire nRST,
	input wire shift_enable,
	input wire serial_in,
	output wire [NUM_BITS-1:0] parallel_out */
);

  	reg [NUM_BITS-1:0] q, n_q;

	assign sif.parallel_out = q;

	always_ff @(posedge sif.clk, negedge sif.nRST) begin
		if (sif.nRST == 1'b0) begin
			q <= '1;
		end
		else begin
			q <= n_q;
		end
	end

	always_comb begin
		n_q = q;
		if (sif.shift_en && SHIFT_MSB) begin
			n_q = {q[NUM_BITS-2:0], sif.serial_in};
		end
		else if (sif.shift_en && ~SHIFT_MSB) begin
			n_q = {sif.serial_in, q[NUM_BITS-1:1]};
		end
	end
endmodule