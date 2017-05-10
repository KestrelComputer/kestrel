`timescale 1ns / 1ps

module address_decode(
	// Processor-side control
	input	iadr_i,
	input	istb_i,
	output	iack_o,

	// ROM-side control
	output	STB_o
);

	// For our example, we're just going to decode address bit A12.
	// If it's high, then we assume we're accessing ROM.
	// The ROM is asynchronous, so we just tie iack_o directly to the
	// the strobe pin.
	wire rom_sel = iadr_i & istb_i;
	assign STB_o = rom_sel;
	assign iack_o = rom_sel;

	// We don't have any RAM resources to access, but if we did,
	// we would decode them here as well.
endmodule
