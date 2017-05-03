`default_nettype none
`timescale 1ns / 1ps

`include "sia.vh"

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
//
// +8	UNUSED			Unused; hardwired 0.
// +10	UNUSED			Unused; hardwired 0.
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
	reg	[15:0]	dat_o;
	reg		ack_o;
	reg		stall_o;

	reg	[4:0]	bits_o;
	reg		eedc_o, eedd_o;
	reg	[2:0]	txcmod_o;
	reg		rxcpol_o;
	reg	[3:0]	intena_o;
	reg	[19:0]	bitrat_o;
	reg		rxq_pop_o;
	reg		rxq_oe_o;
	reg		txq_we_o;
	reg	[15:0]	txq_dat_o;

	wire [3:0] events = {txq_not_full_i, txq_empty_i, rxq_full_i, rxq_not_empty_i};

	always @(posedge clk_i) begin
		dat_o <= 0;
		ack_o <= 0;
		stall_o <= 0;
		bits_o <= bits_o;
		eedc_o <= eedc_o;
		eedd_o <= eedd_o;
		txcmod_o <= txcmod_o;
		rxcpol_o <= rxcpol_o;
		intena_o <= intena_o;
		bitrat_o <= bitrat_o;
		rxq_pop_o <= 0;
		rxq_oe_o <= 0;
		txq_we_o <= 0;
		txq_dat_o <= txq_dat_o;

		if(reset_i) begin
			bits_o <= 10;			// 8N1
			{eedc_o, eedd_o} <= 2'b11;	// Synchronize on edge on either data or clock
			txcmod_o <= 3'b100;		// Data on rising edge of clock
			rxcpol_o <= 0;			// Data synchronized on rising edge of clock
			intena_o <= 4'b0000;		// All interrupts disabled.
			bitrat_o <= 20'd83332;		// 1200bps
		end
		else begin
			if(cyc_i & stb_i & we_i) begin
				case(adr_i)
				`SIA_ADR_CONFIG: begin
					if(sel_i[0]) begin
						bits_o <= dat_i[4:0];
					end
					if(sel_i[1]) begin
						eedc_o <= dat_i[8];
						eedd_o <= dat_i[9];
						txcmod_o <= dat_i[12:10];
						rxcpol_o <= dat_i[13];
					end
				end
				`SIA_ADR_INTENA: begin
					if(sel_i[0]) intena_o <= dat_i[3:0];
				end
				`SIA_ADR_TRXDAT: begin
					if(sel_i[0]) txq_dat_o[7:0] <= dat_i[7:0];
					if(sel_i[1]) txq_dat_o[15:8] <= dat_i[15:8];
					txq_we_o <= sel_i[1];
				end
				`SIA_ADR_zero0: begin /* do nothing */ end
				`SIA_ADR_zero1: begin /* do nothing */ end
				`SIA_ADR_BITRATL: begin
					if(sel_i[0]) bitrat_o[7:0] <= dat_i[7:0];
					if(sel_i[1]) bitrat_o[15:8] <= dat_i[15:8];
				end
				`SIA_ADR_BITRATH: begin
					if(sel_i[0]) bitrat_o[19:16] <= dat_i[3:0];
				end
				endcase
				ack_o <= 1;
			end

			if(cyc_i & stb_i & ~we_i) begin
				case(adr_i)
				`SIA_ADR_CONFIG: dat_o <= {2'd0, rxcpol_o, txcmod_o, eedd_o, eedc_o, 3'd0, bits_o};
				`SIA_ADR_STATUS: dat_o <= {|events, 11'd0, events};
				`SIA_ADR_INTENA: dat_o <= {12'd0, intena_o};
				`SIA_ADR_TRXDAT: begin
					dat_o <= rxq_dat_i;
					rxq_oe_o <= 1;
					rxq_pop_o <= sel_i[1];	// Concession for 8-bit CPUs
				end
				`SIA_ADR_zero0: dat_o <= 0;
				`SIA_ADR_zero1: dat_o <= 0;
				`SIA_ADR_BITRATL: dat_o <= bitrat_o[15:0];
				`SIA_ADR_BITRATH: dat_o <= {12'd0, bitrat_o[19:16]};
				endcase
				ack_o <= 1;
			end
		end
	end
endmodule
