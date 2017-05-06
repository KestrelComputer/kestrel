`default_nettype none
`timescale 1ns / 1ps

// The transmit queue gives the client a (typically, 16) deep FIFO in which
// a processor can store data for eventual transmission.

module sia_txq(
	input		clk_i,
	input		reset_i,

	input	[SRW:0]	dat_i,
	input		we_i,

	input	[BW:0]	bits_i,
	input	[BRW:0]	baud_i,
	input	[2:0]	txcmod_i,

	output		txd_o,
	output		txc_o,
	output		not_full_o,
	output		empty_o,
	output		idle_o
);
	parameter	SHIFT_REG_WIDTH = 16;
	parameter	BITS_WIDTH = 5;
	parameter	BAUD_RATE_WIDTH = 32;
	parameter	DEPTH_BITS = 4;
	parameter	DATA_BITS = SHIFT_REG_WIDTH;

	parameter	BW = BITS_WIDTH - 1;
	parameter	BRW = BAUD_RATE_WIDTH - 1;
	parameter	SRW = SHIFT_REG_WIDTH - 1;

	wire		txc;
	assign		txc_o = (txc & txcmod_i[2]) ^ txcmod_i[0];
	wire	[SRW:0]	txq_dat;
	wire		txq_en, txq_pop, txq_oe, txq_full, txq_empty;
	wire		txq_idle;

	assign		txq_en = txq_idle & ~txq_empty;
	assign		txq_oe = txq_en;
	assign		txq_pop = txq_en;
	assign		empty_o = txq_empty;
	assign		not_full_o = ~txq_full;
	assign		idle_o = txq_idle;

	queue #(
		.DEPTH_BITS(DEPTH_BITS),
		.DATA_BITS(DATA_BITS)
	) q (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.dat_i(dat_i),
		.push_i(we_i),
		.pop_i(txq_pop),
		.oe_i(txq_oe),
		.dat_o(txq_dat),
		.full_o(txq_full),
		.empty_o(txq_empty)
	);

	sia_transmitter #(
		.SHIFT_REG_WIDTH(SHIFT_REG_WIDTH),
		.BAUD_RATE_WIDTH(BAUD_RATE_WIDTH),
		.BITS_WIDTH(BITS_WIDTH)
	) t (
		.clk_i(clk_i),
		.reset_i(reset_i),
		.rxd_i(1'b1),
		.dat_i(txq_dat),
		.txreg_we_i(txq_en),
		.txreg_oe_i(1'b0),
		.txbaud_i(baud_i),
		.bits_i(bits_i),
		.txd_o(txd_o),
		.txc_o(txc),
		.idle_o(txq_idle),
		.brg_o(),
		.bits_o(),
		.dat_o()
	);
endmodule

