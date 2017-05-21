`default_nettype none
`timescale 1ns / 1ps
`include "asserts.vh"

module ipa_tb();
	reg	[11:0]	story_to;
	reg		fault_to;
	reg		clk_i, reset_i, cyc_i;
	reg		txd_i, txc_i;
	wire		ack_o;
	wire	[15:0]	dat_o;

	always begin
		#5 clk_i <= ~clk_i;
	end

	`STANDARD_FAULT
	`DEFASSERT0(ack, o)
	`DEFASSERT(dat, 15, o)

	ipa i(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.cyc_i(cyc_i),
		.ack_o(ack_o),
		.dat_o(dat_o),

		.txd_i(txd_i),
		.txc_i(txc_i)
	);

	task send_byte;
	input [7:0] b;
	begin
		txd_i <= 0; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= b[0]; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= b[1]; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= b[2]; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= b[3]; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= b[4]; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= b[5]; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= b[6]; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= b[7]; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		txd_i <= 1; txc_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		txc_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		wait(~clk_i); wait(clk_i); #1;	// Let ACK_O update
	end
	endtask

	task reset_ipa;
	begin
		wait(~clk_i); wait(clk_i); #1;
		reset_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		reset_i <= 0;
	end
	endtask

	initial begin
		$dumpfile("ipa.vcd");
		$dumpvars;

		{cyc_i, fault_to, txc_i, clk_i, reset_i} <= 0;
		txd_i <= 1;

		// Given an IPA that is NOT currently waiting for data,
		// the receipt of data should not alter the front-side bus.

		story_to <= 12'h000;
		reset_ipa;

		send_byte(0);
		assert_ack(0);
		assert_dat(0);
		send_byte(0);
		assert_ack(0);
		assert_dat(0);
		send_byte(0);
		assert_ack(0);
		assert_dat(0);
		send_byte(0);
		assert_ack(0);
		assert_dat(0);

		// Given an IPA that is currently addressed,
		// the receipt of two bytes should cause ACK to assert.

		story_to <= 12'h010;
		reset_ipa;

		cyc_i <= 1;

		send_byte(8'h11);
		assert_ack(0);
		assert_dat(0);
		send_byte(8'h22);
		assert_ack(1);
		assert_dat(16'h2211);
		send_byte(8'h33);
		assert_ack(0);
		assert_dat(0);
		send_byte(8'h44);
		assert_ack(1);
		assert_dat(16'h4433);

		wait(~clk_i); wait(clk_i);
		cyc_i <= 0;

		#100;
		$display("@I Done.");
		$stop;
	end
endmodule

