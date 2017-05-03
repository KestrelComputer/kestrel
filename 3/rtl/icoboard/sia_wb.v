`default_nettype none
`timescale 1ns / 1ps

// The sia_wb core provides a Wishbone B.4 pipelined compatible slave
// port to allow bus masters to talk to the SIA's receiver and transmitter.
// Additional status bits are exposed beyond those defined by Wishbone,
// providing support for things like interrupts, DMA transfer requests, etc.
//
// This Wishbone interface defines a 16-bit serial controller.
// The following registers are defined.
//
// +0	CONFIG (R/W)
//	...........11111	Specifies character frame length,
//				including start, stop, and parity bits.
//	........000.....	Undefined.
//	.......1........	Enable RXC edge sensitivity.
//	......1.........	Enable RXD edge sensitivity.
//	...111..........	TXC mode.
//		000		Hardwired 0.
//		001		Hardwired 1.
//		010		IEEE-1355 Strobe (*)
//		011		Undefined.
//		100		Idles low; TXD transitions on rising edge.
//		101		Idles high; TXD transitions on falling edge.
//		110		Idles low; TXD transitions on falling edge.(*)
//		111		Idles high; TXD transitions on rising edge.(*)
//		* - reserved for this purpose, but might not be implemented.
//	..1.............	RXC edge polarity
//		0		Idles low; sensitive on rising edge.
//		1		Idles high; sensitive on falling edge.
//	00..............	Undefined.
//
// +2	STATUS	(R/O)
//	...............1	RX FIFO *not* empty.
//	..............1.	RX FIFO is full.
//	.............1..	TX FIFO *is* empty.
//	............1...	TX FIFO is *not* full.
//	.00000000000....	Undefined.
//	1...............	One or more other bits set.
//
// +4	INTENA	(R/W)
//	...............1	RX FIFO *not* empty.
//	..............1.	RX FIFO is full.
//	.............1..	TX FIFO *is* empty.
//	............1...	TX FIFO is *not* full.
//	000000000000....	Undefined.
//	
// +6	RCVDAT (R/O)
// +6	SNDDAT (W/O)
// +8	RCVDAT (R/O) (bit-reversed)
// +8	SNDDAT (W/O) (bit-reversed)
//
// +10	UNUSED			Unused.
//
// +12	BITRATL			Baud rate generator.
// +14	BITRATH
//	1111111111111111	Lower bits of divisor.
//	0000000000001111	Upper bits of divisor.
//				Bit rate = 100Mbps / (divisor + 1)
//
// Total register space taken is 16 bytes.

module sia_wb(
	input		clk_i,
	input		reset_i,

	input	[3:1]	adr_i,
	input		we_i,
	input		cyc_i,
	input		stb_i,
	input	[1:0]	sel_i,
	input	[15:0]	dat_i,
	output	[15:0]	dat_o,
	output		ack_o,
	output		stall_o,
	output		irq_o,

	output	[4:0]	bits_o,
	output		eedc_o,
	output		eedd_o,
	output	[2:0]	txcmod_o,
	output		rxcpol_o,
	output	[3:0]	intena_o,
	output	[19:0]	bitrat_o,

	output		rxq_pop_o,
	output		rxq_oe_o,
	input	[15:0]	rxq_dat_i,
	input		rxq_full_i,
	input		rxq_not_empty_i,

	output		txq_we_o,
	output	[15:0]	txq_dat_o,
	input		txq_not_full_i,
	input		txq_empty_i
);
endmodule
