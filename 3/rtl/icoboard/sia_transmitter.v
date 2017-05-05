`default_nettype none
`timescale 1ns / 1ps

module sia_transmitter(
	input		clk_i,
	input		reset_i,

	input		rxd_i,
	input	[SRW:0]	dat_i,

	input		txreg_we_i,
	input		txreg_oe_i,
	input	[BRG:0]	txbaud_i,
	input	[BW:0]	bits_i,

	output		txd_o,
	output		txc_o,
	output		idle_o,
	output	[BRG:0]	brg_o,
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
	reg	[BRG:0]	brg_o;
	reg	[SRW:0]	shift_register;
	reg		txc_o;

	assign		txd_o = shift_register[0];
	assign		idle_o = ~|bits_o;

	wire		txreg_shift = ~|brg_o;
	wire	[BRG:1]	halfbit = txbaud_i[BRG:1];

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

