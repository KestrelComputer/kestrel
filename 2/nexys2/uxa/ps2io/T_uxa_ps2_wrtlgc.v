`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:30:35 10/30/2011
// Design Name:   M_uxa_ps2_wrtlgc
// Module Name:   /Users/kc5tja/tmp/kestrel/2/nexys2/uxa/ps2io/T_uxa_ps2_wrtlgc.v
// Project Name:  ps2io
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: M_uxa_ps2_wrtlgc
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module T_uxa_ps2_wrtlgc;

	// Inputs
	reg frame_i;
	reg sys_clk_i;
	reg sys_reset_i;

	// Outputs
	wire reset_o;
	wire we_o;
	wire ptr_inc_o;

	// Instantiate the Unit Under Test (UUT)
	M_uxa_ps2_wrtlgc uut (
		.frame_i(frame_i), 
		.reset_o(reset_o), 
		.we_o(we_o), 
		.ptr_inc_o(ptr_inc_o), 
		.sys_clk_i(sys_clk_i), 
		.sys_reset_i(sys_reset_i)
	);

	always begin
		#40; sys_clk_i <= ~sys_clk_i;
	end

	initial begin
		// Initialize Inputs
		frame_i = 0;
		sys_clk_i = 0;
		sys_reset_i = 0;

		// Reset test
		#80; sys_reset_i = 1;
		#80; sys_reset_i = 0;
		#80; if (we_o != 0) begin
			$display("No frame yet -- nothing to write!"); $stop;
		end
		if (reset_o != 0) begin
			$display("Nothing to reset yet!"); $stop;
		end
		if (ptr_inc_o != 0) begin
			$display("No written yet -- why increment the pointer?"); $stop;
		end

		// And, as if by magic, a byte arrives at the PS/2 port, and
		// needs processing.  Let's stuff it in the FIFO!.
		#160;
		frame_i = 1; #80; frame_i = 0; #40;
		if (we_o != 1) begin
			$display("We should be writing to the queue now."); $stop;
		end
		if (reset_o != 0) begin
			$display("We shouldn't yet be resetting the deserializer yet."); $stop;
		end
		if (ptr_inc_o != 0) begin
			$display("We shouldn't yet be bumping the write pointer."); $stop;
		end
		
		// After the write phase, we check the reset and bump phase.
		#80;
		if (we_o != 0) begin
			$display("We need to finish the write operation before bumping the FIFO write pointer."); $stop;
		end
		if (reset_o != 1) begin
			$display("With the byte written, we should be resetting the deserializer for the next byte to come in."); $stop;
		end
		if (ptr_inc_o != 1) begin
			$display("With the byte written, we should be incrementing the queue's write pointer."); $stop;
		end
	end
      
endmodule

