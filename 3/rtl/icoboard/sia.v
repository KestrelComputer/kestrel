`default_nettype none
`timescale 1ns / 1ps

// The SIA core provides a EIA-232/422-compatible bit-serial interface.
// The SIA is basically broken up into three parts: the Wishbone B4
// slave interface, the transmitter, and the receiver.
// 
// This core exposes a 16-bit data bus width.
//
// NOTE: This module exposes a STALL_O signal.  However, this
// module currently never stalls the master.  The SIA core will always
// acknowledge a transfer one cycle after it's registered.

module sia(
	input		clk_i,
	input		reset_i,

	input		cyc_i,
	input		stb_i,
	input		we_i,
	input	[1:0]	sel_i,
	input	[2:1]	adr_i,
	input	[15:0]	dat_i,
	output		ack_o,
	output	[15:0]	dat_o,
	output		stall_o
);
endmodule

