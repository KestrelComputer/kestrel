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
//		110		Idles low; TXD transitions on falling edge. (*)
//		111		Idles high; TXD transitions on rising edge. (*)
//	..1.............	RXC edge polarity
//		0		Idles low; sensitive on rising edge.
//		1		Idles high; sensitive on falling edge.
//	00..............	Undefined.
//
//	* - reserved for this purpose, but might not be implemented.
//	If unimplemented, setting will yield undefined results.
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
//
// +8	UNUSED			Unused.
// +10	UNUSED			Unused.
//
// +12	BITRATL			Baud rate generator.
// +14	BITRATH
//	1111111111111111	Lower bits of divisor.
//	0000000000001111	Upper bits of divisor.
//
//				Bit rate = 100Mbps / (divisor+1)
//				(for icoBoard Gamma platform)
//
// Total register space taken is 16 bytes.

module sia_wb_tb();
	reg		clk_i, reset_i;
	reg	[11:0]	story_to;

	reg	[3:1]	adr_i;
	reg		we_i, cyc_i, stb_i;
	reg	[15:0]	dat_i;
	reg	[1:0]	sel_i;
	wire	[15:0]	dat_o;
	wire		ack_o, irq_o, stall_o;

	wire	[4:0]	bits_o;
	wire		eedc_o;
	wire		eedd_o;
	wire	[2:0]	txcmod_o;
	wire		rxcpol_o;
	wire	[3:0]	intena_o;
	wire	[19:0]	bitrat_o;

	wire		rxq_pop_o;
	wire		rxq_oe_o;
	reg	[15:0]	rxq_dat_i;
	reg		rxq_full_i;
	reg		rxq_not_empty_i;

	wire		txq_we_o;
	wire	[15:0]	txq_dat_o;
	reg		txq_not_full_i;
	reg		txq_empty_i;

	always begin
		#5; clk_i <= ~clk_i;
	end

	sia_wb wbs(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.adr_i(adr_i),
		.we_i(we_i),
		.cyc_i(cyc_i),
		.stb_i(stb_i),
		.dat_i(dat_i),
		.sel_i(sel_i),
		.dat_o(dat_o),
		.ack_o(ack_o),
		.irq_o(irq_o),

		.bits_o(bits_o),
		.eedc_o(eedc_o),
		.eedd_o(eedd_o),
		.txcmod_o(txcmod_o),
		.rxcpol_o(rxcpol_o),
		.intena_o(intena_o),
		.bitrat_o(bitrat_o),

		.rxq_pop_o(rxq_pop_o),
		.rxq_oe_o(rxq_oe_o),
		.rxq_dat_i(rxq_dat_i),
		.rxq_full_i(rxq_full_i),
		.rxq_not_empty_i(rxq_not_empty_i),

		.txq_we_o(txq_we_o),
		.txq_dat_o(txq_dat_o),
		.txq_not_full_i(txq_not_full_i),
		.txq_empty_i(txq_empty_i)
	);

	initial begin
		$dumpfile("sia_wb.vcd");
		$dumpvars;

		{adr_i, we_i, cyc_i, stb_i, sel_i, dat_i, clk_i, reset_i, rxq_dat_i, rxq_full_i, rxq_not_empty_i, txq_not_full_i, txq_empty_i} <= 0;

		wait(~clk_i); wait(clk_i); #1;
		reset_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		reset_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		#100;
		$display("@I Done.");
		$stop;
	end
endmodule

