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

module sia_receiver(
	input		clk_i,
	input		reset_i,

	// These inputs correspond to fields found in the register
	// set of the receiver.  Register set not included.

	input	[BW:0]	bits_i,
	input	[BRW:0]	baud_i,
	input		eedd_i,	// Enable Edge Detect on Data
	input		eedc_i, // Enable Edge Detect on Clock

	// Inputs from external hardware

	input		rxd_i,
	input		rxc_i,

	// Outputs to receiver FIFO.

	output	[SRW:0]	dat_o,
	output		idle_o,

	// Test outputs.

	output		sample_to
);
	parameter	SHIFT_REG_WIDTH = 16;
	parameter	BAUD_RATE_WIDTH = 32;
	parameter	BITS_WIDTH = 5;

	parameter	SRW = SHIFT_REG_WIDTH - 1;
	parameter	BRW = BAUD_RATE_WIDTH - 1;
	parameter	BW = BITS_WIDTH - 1;

	reg	[SRW:0]	shiftRegister;
	reg	[BRW:0]	sampleCtr;
	reg	[BW:0]	bitsLeft;
	reg		d0, d1, c0, c1;

	wire edgeDetected = (eedd_i & (d0 ^ d1)) | (eedc_i & (~c1 & c0));
	wire sampleBit = ~idle_o && (sampleCtr == 0);
	wire	[SRW:0]	shiftRegister_rev;

	genvar i;
	generate
		for(i = 0; i <= SRW; i = i + 1) begin
			assign shiftRegister_rev[i] = shiftRegister[SRW-i];
		end
	endgenerate

	assign idle_o = (bitsLeft == 0);
	assign dat_o = shiftRegister;

	always @(posedge clk_i) begin
		shiftRegister <= shiftRegister;
		bitsLeft <= bitsLeft;
		sampleCtr <= sampleCtr;
		d1 <= d0;
		d0 <= rxd_i;
		c1 <= c0;
		c0 <= rxc_i;

		if(reset_i) begin
			shiftRegister <= ~(0);
			bitsLeft <= 0;
			sampleCtr <= baud_i;
			d0 <= 1;
			d1 <= 1;
		end

		else begin
			if(edgeDetected) begin
				if(idle_o) begin
					bitsLeft <= bits_i;
				end
				sampleCtr <= {1'b0, baud_i[BRW:1]};
			end
			else if(sampleBit) begin
				sampleCtr <= baud_i;
				bitsLeft <= bitsLeft - 1;
				shiftRegister <= {d0, shiftRegister[SRW:1]};
			end
			else if(idle_o) begin
				sampleCtr <= baud_i;
			end
			else begin
				sampleCtr <= sampleCtr - 1;
			end
		end
	end

	assign sample_to = sampleBit;
endmodule

