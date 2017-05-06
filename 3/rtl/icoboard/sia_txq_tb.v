`default_nettype none
`timescale 1ns / 1ps

`include "asserts.vh"

module sia_txq_tb();
	reg		story_to, fault_to;
	reg		clk_i, reset_i;
	reg	[11:0]	dat_i;
	reg		we_i;
	wire		txd_o, txc_o, not_full_o, empty_o, idle_o;

	sia_txq #(
		.SHIFT_REG_WIDTH(12),
		.BAUD_RATE_WIDTH(32),
		.DEPTH_BITS(2)
	) x(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.dat_i(dat_i),
		.we_i(we_i),

		.bits_i(5'd10),			// 8N1
		.baud_i(32'd49),		// 1Mbps when clocked at 50MHz.
		.txcmod_i(3'b100),

		.txd_o(txd_o),
		.txc_o(txc_o),

		.not_full_o(not_full_o),
		.empty_o(empty_o),
		.idle_o(idle_o)
	);

	always begin
		#10 clk_i <= ~clk_i;
	end

	`STANDARD_FAULT
	`DEFASSERT0(txd, o)
	`DEFASSERT0(idle, o)
	`DEFASSERT0(empty, o)
	`DEFASSERT0(not_full, o)

	initial begin
		$dumpfile("sia_txq.vcd");
		$dumpvars;

		{clk_i, reset_i, dat_i, we_i} <= 0;
		wait(~clk_i); wait(clk_i); #1;
		
		reset_i <= 1;
		wait(~clk_i); wait(clk_i); #1;

		reset_i <= 0;
		wait(~clk_i); wait(clk_i); #1;
		wait(~clk_i); wait(clk_i); #1;

		// Write a single value to the queue.
		// Transmission should start soon thereafter.

		dat_i <= 12'b111_11101101_0;
		we_i <= 1;
		wait(~clk_i); wait(clk_i); #1;
		we_i <= 0;
		wait(~clk_i); wait(clk_i); #1;

		wait(txc_o); wait(~txc_o);
		assert_txd(0);
		assert_idle(0);
		assert_empty(1);	// EMPTY reports FIFO status, not engine status.
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(1);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(0);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(1);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(1);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(0);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(1);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(1);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(1);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		wait(txc_o); wait(~txc_o);
		assert_txd(1);
		assert_idle(0);
		assert_empty(1);
		assert_not_full(1);
		#1000;	// No TXC to wait on, so fake it 'til you make it.
		assert_txd(1);
		assert_idle(1);
		assert_empty(1);
		assert_not_full(1);
		wait(~clk_i); wait(clk_i); #1;

		// Keep writing until we fill the queue.  For this test's
		// configuration, that should amount to FIVE values.
		// The first four are provided by the FIFO, and the third
		// is whatever the engine has consumed and is currently
		// sending.

		dat_i <= 12'b111_11101101_0;
		we_i <= 1;
		fault_to <= 0;
		wait(~clk_i); wait(clk_i); #1;		// Fills FIFO(0)
		assert_empty(0);
		assert_not_full(1);
		fault_to <= 1;
		wait(~clk_i); wait(clk_i); #1;		// TXE activated; refills FIFO(0)
		assert_empty(0);
		assert_not_full(1);
		fault_to <= 0;
		wait(~clk_i); wait(clk_i); #1;		// Fills FIFO(1)
		assert_empty(0);
		assert_not_full(1);
		fault_to <= 1;
		wait(~clk_i); wait(clk_i); #1;		// Fills FIFO(2)
		assert_empty(0);
		assert_not_full(1);
		fault_to <= 0;
		wait(~clk_i); wait(clk_i); #1;		// Fills FIFO(3); now full.
		assert_empty(0);
		assert_not_full(0);
		fault_to <= 1'bX;
		we_i <= 0;

		#10000;		// Wait for all five characters to be sent.
		assert_empty(0);
		assert_not_full(1);

		#10000;
		assert_empty(0);
		assert_not_full(1);

		#10000;
		assert_empty(0);
		assert_not_full(1);

		#10000;
		assert_empty(0);
		assert_not_full(1);

		#10000;
		assert_empty(1);
		assert_not_full(1);

		#100;
		$display("@I Done.");
		$stop;
	end
endmodule
