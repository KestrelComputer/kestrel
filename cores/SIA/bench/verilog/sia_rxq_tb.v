`default_nettype none
`timescale 1ns / 1ps

module sia_rxq_tb();
	reg	[15:0]	story;
	reg		clk_i = 0, reset_i = 0;
	reg		rxd_i = 1, rxc_i = 0;
	reg		rxq_pop_i = 0;
	reg		rxq_oe_i = 0;
	wire	[11:0]	rxq_dat_o;
	wire		rxq_full_o, rxq_not_empty_o;

	sia_rxq #(
		.SHIFT_REG_WIDTH(12),
		.BAUD_RATE_WIDTH(32),
		.DEPTH_BITS(2),
		.DATA_BITS(12)
	) x(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.bits_i(5'd10),			// 8N1
		.baud_i(32'd49),		// 1Mbps when clocked at 50MHz.
		.eedd_i(1'b1),
		.eedc_i(1'b1),
		.rxcpol_i(1'b0),

		.rxd_i(rxd_i),
		.rxc_i(rxc_i),

		.rxq_pop_i(rxq_pop_i),
		.rxq_oe_i(rxq_oe_i),
		.rxq_dat_o(rxq_dat_o),
		.rxq_full_o(rxq_full_o),
		.rxq_not_empty_o(rxq_not_empty_o)
	);

	always begin
		#10 clk_i <= ~clk_i;
	end

	task assert_queue_not_empty;
	input expected;
	begin
		if (expected !== rxq_not_empty_o) begin
			$display("@E %d rxq_not_empty_o Expected %d; got %d", story, expected, rxq_not_empty_o);
			$stop;
		end
	end
	endtask

	task assert_queue_full;
	input expected;
	begin
		if (expected !== rxq_full_o) begin
			$display("@E %d rxq_full_o Expected %d; got %d", story, expected, rxq_full_o);
			$stop;
		end
	end
	endtask

	task assert_dat;
	input [11:0] expected;
	begin
		if (expected !== rxq_dat_o) begin
			$display("@E %d rxq_dat_o Expected %012B; got %012B", story, expected, rxq_dat_o);
			$stop;
		end
	end
	endtask

	initial begin
		$dumpfile("sia_rxq.vcd");
		$dumpvars;

		story <= 1;
		reset_i <= 1;

		wait(clk_i); wait(~clk_i);

		reset_i <= 0;
		rxq_pop_i <= 1;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);

		rxq_pop_i <= 0;

		assert_dat(12'h000);
		assert_queue_not_empty(0);
		assert_queue_full(0);

		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 1; #1000;

		assert_queue_not_empty(1);
		assert_queue_full(0);

		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 1; #1000;

		assert_queue_not_empty(1);
		assert_queue_full(0);

		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 1; #1000;

		assert_queue_not_empty(1);
		assert_queue_full(0);

		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 0; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 1; #1000;

		assert_queue_not_empty(1);
		assert_queue_full(1);

		story <= 2;
		rxq_oe_i <= 1;
		wait(clk_i); wait(~clk_i);

		assert_dat(12'b1_10000101_0_11);
		assert_queue_not_empty(1);
		assert_queue_full(1);

		wait(clk_i); wait(~clk_i);

		assert_dat(12'b1_10000101_0_11);
		assert_queue_not_empty(1);
		assert_queue_full(1);

		rxq_pop_i <= 1;

		wait(clk_i); wait(~clk_i);
		assert_dat(12'b1_10100001_0_11);
		assert_queue_not_empty(1);
		assert_queue_full(0);

		wait(clk_i); wait(~clk_i);
		assert_dat(12'b1_10000101_0_11);
		assert_queue_not_empty(1);
		assert_queue_full(0);

		wait(clk_i); wait(~clk_i);
		assert_dat(12'b1_10100001_0_11);
		assert_queue_not_empty(1);
		assert_queue_full(0);

		wait(clk_i); wait(~clk_i);
		assert_dat(12'b1_10000101_0_11);	// Data read ptr wraps around to beginning
		assert_queue_not_empty(0);
		assert_queue_full(0);

		wait(clk_i); wait(~clk_i);
		assert_dat(12'b1_10000101_0_11);	// ... and stays there when empty.
		assert_queue_not_empty(0);
		assert_queue_full(0);

		$display("@I Done.");
		$stop;
	end
endmodule
