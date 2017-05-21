`default_nettype none
`timescale 1ns / 1ps

module ipa_tb();
	reg		clk_i, reset_i;

	always begin
		#5 clk_i <= ~clk_i;
	end

	initial begin
		$dumpfile("ipa.vcd");
		$dumpvars;

		{clk_i, reset_i} <= 0;

		#100;
		$display("@I Done.");
		$stop;
	end
endmodule

