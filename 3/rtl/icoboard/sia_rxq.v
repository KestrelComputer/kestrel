`default_nettype none
`timescale 1ns / 1ps

// The receiver core provides a ITU V.4-compatible bit-serial interface.
// The receiver is broadly broken up into three parts: the Wishbone B4
// slave interface, the transmitter, and the receiver.
// 
// This module defines the V.4-compatible receiver.
//
// Note that if both eedd_i and eedc_i are low, the receiver never
// sees any edges to transition with, and therefore can be used to
// disable the receiver.
//
//	eedd_i	eedc_i	Results
//	0	0	Disable receiver.
//	0	1	Receiver clocks on RXC input only. [1]
//	1	0	Receiver clocks on RXD input only. [2]
//	1	1	Receiver clocks on any edge it can find. [1, 2]
//
//	Note 1: Only the rising edge of RXC is recognized.
//	Note 2: Both rising AND falling edges of RXD are recognized.

module sia_rxq(
	input		clk_i,
	input		reset_i,

	// These inputs correspond to fields found in the register
	// set of the receiver.  Register set not included.

	input	[BW:0]	bits_i,
	input	[BRW:0]	baud_i,
	input		eedd_i,
	input		eedc_i,

	// Inputs from external hardware

	input		rxd_i,
	input		rxc_i,

	// FIFO outputs.

	input		rxq_pop_i,
	input		rxq_oe_i,
	output	[SRW:0]	rxq_dat_o,
	output		rxq_full_o,
	output		rxq_not_empty_o
);
	parameter	SHIFT_REG_WIDTH = 16;
	parameter	BAUD_RATE_WIDTH = 32;
	parameter	BITS_WIDTH = 5;
	parameter	DATA_BITS = SHIFT_REG_WIDTH;
	parameter	DEPTH_BITS = 4;

	parameter	BRW = BAUD_RATE_WIDTH - 1;
	parameter	SRW = SHIFT_REG_WIDTH - 1;
	parameter	BW = BITS_WIDTH - 1;

	wire		rx_rq_idle;
	reg		rx_rq_idle_dly;
	wire	[SRW:0]	rx_rq_dat;
	wire		rxq_empty_o;
	assign		rxq_not_empty_o = ~rxq_empty_o;

	always @(posedge clk_i) begin
		if(reset_i) begin
			rx_rq_idle_dly <= 0;
		end
		else begin
			rx_rq_idle_dly <= rx_rq_idle;
		end
	end

	sia_receiver #(
		.SHIFT_REG_WIDTH(SHIFT_REG_WIDTH),
		.BAUD_RATE_WIDTH(BAUD_RATE_WIDTH)
	) rx (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.bits_i(bits_i),
		.baud_i(baud_i),
		.eedd_i(eedd_i),
		.eedc_i(eedc_i),
		.rxd_i(rxd_i),
		.rxc_i(rxc_i),
		.dat_o(rx_rq_dat),
		.idle_o(rx_rq_idle),

		.sample_to()
	);

	queue #(
		.DEPTH_BITS(DEPTH_BITS),
		.DATA_BITS(DATA_BITS)
	) rq (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.dat_i(rx_rq_dat),
		.push_i(rx_rq_idle & ~rx_rq_idle_dly),
		.pop_i(rxq_pop_i),
		.oe_i(rxq_oe_i),
		.dat_o(rxq_dat_o),
		.full_o(rxq_full_o),
		.empty_o(rxq_empty_o),

		.rp_to(),
		.wp_to(),
		.room_to()
	);
endmodule

