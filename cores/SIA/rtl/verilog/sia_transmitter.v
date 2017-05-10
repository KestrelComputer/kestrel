`default_nettype none
`timescale 1ns / 1ps

// The transmitter core provides an ITU V.4-compatible bit-serial interface.
// This core is based on R&D work performed on the XST (Experimental Serial
// Transmitter) project, and has been feature-reduced to meet the SIA's
// needs.
//
// NOTE: TXC output is always idle-low, active high.  TXC conditioning for
// polarity or hardwired 1 or 0 must be done externally to this core.
// Similarly with any loop-back features.
//
// IDLE_O asserts when the transmitter has completed sending a frame.  This
// can be used to conditionally drive an external FIFO to automatically
// refill the transmit shift register.

module sia_transmitter(
	input		clk_i,
	input		reset_i,

	input		rxd_i,
	input	[SRW:0]	dat_i,

	input		txreg_we_i,
	input		txreg_oe_i,
	input	[BRW:0]	txbaud_i,
	input	[BW:0]	bits_i,

	output		txd_o,
	output		txc_o,
	output		idle_o,
	output	[BRW:0]	brg_o,
	output	[BW:0]	bits_o,
	output	[SRW:0]	dat_o
);
	parameter	SHIFT_REG_WIDTH = 16;
	parameter	BAUD_RATE_WIDTH = 32;
	parameter	BITS_WIDTH = 5;

	parameter	SRW = SHIFT_REG_WIDTH - 1;
	parameter	BRW = BAUD_RATE_WIDTH - 1;
	parameter	BW = BITS_WIDTH - 1;

	reg	[BW:0]	bits_o;
	reg	[BRW:0]	brg_o;
	reg	[SRW:0]	shift_register;
	reg		txc_o;

	assign		txd_o = shift_register[0];
	assign		idle_o = ~|bits_o;

	wire		txreg_shift = ~|brg_o;
	wire	[BRW:1]	halfbit = txbaud_i[BRW:1];

	assign		dat_o = (txreg_oe_i ? shift_register : 0);

	always @(posedge clk_i) begin
		shift_register <= shift_register;
		brg_o <= brg_o;
		txc_o <= txc_o;
		bits_o <= bits_o;

		if(reset_i) begin
			shift_register <= ~0;
			brg_o <= 0;
			txc_o <= 0;
			bits_o <= 0;
		end

		else if(txreg_we_i) begin
			brg_o <= txbaud_i;
			txc_o <= 1;
			shift_register <= dat_i;
			bits_o <= bits_i;
		end

		else begin
			if(txreg_shift & ~idle_o) begin
				brg_o <= txbaud_i;
				txc_o <= (bits_o != 1);
				shift_register <= {rxd_i, shift_register[SRW:1]};
				bits_o <= bits_o - 1;
			end
			else if(~txreg_shift & ~idle_o) begin
				brg_o <= brg_o - 1;
			end
		end

		if(brg_o == {1'b0, halfbit}) begin
			txc_o <= 0;
		end
	end
endmodule

