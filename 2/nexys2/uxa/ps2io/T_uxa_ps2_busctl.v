`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:23:42 10/30/2011
// Design Name:   M_uxa_ps2_busctl
// Module Name:   /Users/kc5tja/tmp/kestrel/2/nexys2/uxa/ps2io/T_uxa_ps2_busctl.v
// Project Name:  ps2io
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: M_uxa_ps2_busctl
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module T_uxa_ps2_busctl;

	// Inputs
	reg sys_clk_i;
	reg sys_reset_i;
	reg wb_we_i;
	reg wb_stb_i;
	reg wb_dat_8_i;
	reg wb_dat_9_i;

	// Outputs
	wire wb_ack_o;
	wire rp_inc_o;
	wire c_oe_o;
	wire d_oe_o;

	// Instantiate the Unit Under Test (UUT)
	M_uxa_ps2_busctl uut (
		.sys_clk_i(sys_clk_i), 
		.sys_reset_i(sys_reset_i), 
		.wb_we_i(wb_we_i), 
		.wb_stb_i(wb_stb_i), 
		.wb_dat_8_i(wb_dat_8_i), 
		.wb_dat_9_i(wb_dat_9_i), 
		.wb_ack_o(wb_ack_o), 
		.rp_inc_o(rp_inc_o), 
		.c_oe_o(c_oe_o), 
		.d_oe_o(d_oe_o)
	);

	always begin
		#40 sys_clk_i = ~sys_clk_i;
	end

	initial begin
		// Initialize Inputs
		sys_clk_i = 0;
		sys_reset_i = 0;
		wb_we_i = 0;
		wb_stb_i = 0;
		wb_dat_8_i = 0;
		wb_dat_9_i = 0;

		// Wait 100 ns for global reset to finish
		#80; sys_reset_i = 1; #80; sys_reset_i = 0;
		#80; if (c_oe_o != 0) begin
			$display("clock driver unexpectedly enabled"); $stop;
		end
		if (d_oe_o != 0) begin
			$display("data driver unexpectedly enabled"); $stop;
		end
		if (wb_ack_o != 0) begin
			$display("bus activity detected when there shouldn't be any"); $stop;
		end
		if (rp_inc_o != 0) begin
			$display("FIFO bump control unexpectedly set"); $stop;
		end
		
		// Let's try reading from the interface.
		wait(~sys_clk_i);
		wait(sys_clk_i);
		wb_we_i <= 0; wb_stb_i <= 1; #20;
		if (wb_ack_o != 1) begin
			$display("We expect single-cycle response time from acknowledgement"); $stop;
		end
		#40;
		if (rp_inc_o != 0) begin
			$display("Wait for it...wait for it..."); $stop;
		end
		#20;
		if (rp_inc_o != 0) begin
			$display("Trick question -- rp_inc_o should never assert for a simple read."); $stop;
		end
		wb_stb_i <= 0; #80;

		// Let's try writing to the interface now.  We'll leave the
		// data bus inputs set to zero, which should cause our output
		// enables to go high.  We'll also verify that the FIFO gets
		// popped too.
		wait(~sys_clk_i);
		wait(sys_clk_i);
		wb_we_i <= 1; wb_stb_i <= 1; #20;
		if (wb_ack_o != 1) begin
			$display("We expect single-cycle response time from acknowledgement"); $stop;
		end
		#40;
		if (rp_inc_o != 0) begin
			$display("Wait for it...wait for it... (part 2)"); $stop;
		end
		#20;
		if (rp_inc_o != 0) begin
			$display("rp_inc should assert for a write, but only after the transaction is logged."); $stop;
		end
		wb_stb_i <= 0; #80;

		// Back-to-back writes should result in repeated FIFO pops.
		wait(~sys_clk_i);
		wait(sys_clk_i);
		wb_we_i <= 1; wb_stb_i <= 1;
		wait(~sys_clk_i);
		wait(sys_clk_i);
		#20;
		if (rp_inc_o != 1) begin
			$display("First pop should be in progress now."); $stop;
		end
		wait(~sys_clk_i);
		wait(sys_clk_i);
		#20;
		if (rp_inc_o != 1) begin
			$display("Second pop should be in progress now."); $stop;
		end
		wb_we_i <= 0; wb_stb_i <= 0;
		wait(~sys_clk_i);
		wait(sys_clk_i);
		#20;
		if (rp_inc_o != 0) begin
			$display("We had two back-to-back writes, not three."); $stop;
		end
	end
      
endmodule

