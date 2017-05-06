`default_nettype none
`timescale 1ns / 1ps

`include "asserts.vh"

module sia_txq_tb();
	reg		story_to, fault_to;
	reg		clk_i, reset_i;
	reg	[11:0]	dat_i;
	reg		we_i;
	wire		txd_o, txc_o, not_full_o, empty_o, idle_o;

	sia_txq #(
		.SHIFT_REG_WIDTH(12),
		.BAUD_RATE_WIDTH(32),
		.DEPTH_BITS(2)
	) x(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.dat_i(dat_i),
		.we_i(we_i),

		.bits_i(5'd10),			// 8N1
		.baud_i(32'd49),		// 1Mbps when clocked at 50MHz.
		.txcmod_i(3'b100),

		.txd_o(txd_o),
		.txc_o(txc_o),

		.not_full_o(not_full_o),
		.empty_o(empty_o),
		.idle_o(idle_o)
	);

	always begin
		#10 clk_i <= ~clk_i;
	end

	`STANDARD_FAULT

	initial begin
		$dumpfile("sia_txq.vcd");
		$dumpvars;

		{clk_i, reset_i, dat_i, we_i} <= 0;
		wait(~clk_i); wait(clk_i); #1;
		
		reset_i <= 1;
		wait(~clk_i); wait(clk_i); #1;

		reset_i <= 0;
		wait(~clk_i); wait(clk_i); #1;
		wait(~clk_i); wait(clk_i); #1;

		dat_i <= 12'b111_11101101_0;
		we_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		we_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		wait(idle_o);
		#100;

		$display("@I Done.");
		$stop;
	end
endmodule
