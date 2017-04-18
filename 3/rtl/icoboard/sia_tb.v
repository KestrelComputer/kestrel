`default_nettype none
`timescale 1ns / 1ps

// The SIA core provides a EIA-232/422-compatible bit-serial interface.
// The SIA is basically broken up into three parts: the Wishbone B4
// slave interface, the transmitter, and the receiver.
// 
// This core exposes a 16-bit data bus width.

module sia_tb();
	reg		clk_i, reset_i;
	reg		cyc_i, stb_i, we_i;
	reg	[1:0]	sel_i;
	reg	[2:1]	adr_i;
	reg	[15:0]	dat_i;
	wire		ack_o;
	wire	[15:0]	dat_o;
	wire		stall_o;

	sia s(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.cyc_i(cyc_i),
		.stb_i(stb_i),
		.we_i(we_i),
		.sel_i(sel_i),
		.adr_i(adr_i),
		.dat_i(dat_i),
		.ack_o(ack_o),
		.dat_o(dat_o),
		.stall_o(stall_o)
	);

	always begin
		#10 clk_i <= ~clk_i;
	end

	initial begin
		$dumpfile("sia.vcd");
		$dumpvars;

		{clk_i, reset_i, cyc_i, stb_i, we_i, sel_i, adr_i, dat_i} = 0;

		$display("@I Done.");
		$stop;
	end
endmodule

