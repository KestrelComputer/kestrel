`default_nettype none
`timescale 1ns / 1ps

module sia_receiver_tb();
	reg	[15:0]	story;
	reg		clk_i = 0, reset_i = 0;
	reg		rxd_i = 1, rxc_i = 0;
	reg		rxreg_oe_i = 0, rxregr_oe_i = 0;

	wire		idle_o;
	wire	[63:0]	dat_o;

	wire		sample_to;

	sia_receiver #(
		.SHIFT_REG_WIDTH(64),
		.BAUD_RATE_WIDTH(32),
		.BITS_WIDTH(5)
	) x(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.bits_i(5'd11),			// 8O1
		.baud_i(32'd49),		// 1Mbps when clocked at 50MHz.
		.eedd_i(1'b1),
		.eedc_i(1'b1),

		.rxd_i(rxd_i),
		.rxc_i(rxc_i),

		.dat_o(dat_o),
		.idle_o(idle_o),

		.sample_to(sample_to)
	);

	always begin
		#10 clk_i <= ~clk_i;
	end

	task assert_idle;
	input expected;
	begin
		if (expected !== idle_o) begin
			$display("@E %d idle_o Expected %d; got %d", story, expected, idle_o);
			$stop;
		end
	end
	endtask

	task assert_dat;
	input [63:0] expected;
	begin
		if (expected !== dat_o) begin
			$display("@E %d dat_o Expected %064B; got %064B", story, expected, dat_o);
			$stop;
		end
	end
	endtask

	initial begin
		$dumpfile("sia_receiver.vcd");
		$dumpvars;

		story <= 1;
		reset_i <= 1;

		wait(clk_i); wait(~clk_i);

		reset_i <= 0;

		assert_idle(1);
		assert_dat(64'hFFFFFFFFFFFFFFFF);
		
		rxd_i <= 0; #1000; assert_dat({1'b0, ~(63'h0)});
		rxd_i <= 1; #1000; assert_dat({2'b10, ~(62'h0)});
		rxd_i <= 0; #1000; assert_dat({3'b010, ~(61'h0)});
		rxd_i <= 1; #1000; assert_dat({4'b1010, ~(60'h0)});
		rxd_i <= 0; #1000; assert_dat({5'b01010, ~(59'h0)});
		rxd_i <= 0; #1000; assert_dat({6'b001010, ~(58'h0)});
		rxd_i <= 0; #1000; assert_dat({7'b0001010, ~(57'h0)});
		rxd_i <= 0; #1000; assert_dat({8'b00001010, ~(56'h0)});
		rxd_i <= 1; #1000; assert_dat({9'b100001010, ~(55'h0)});
		rxd_i <= 0; #1000; assert_dat({10'b0100001010, ~(54'h0)});
		rxd_i <= 1; #1000; assert_dat({11'b10100001010, ~(53'h0)});
		rxd_i <= 0; #1000; assert_dat({12'b010100001010, ~(52'h0)});

		rxd_i <= 1; #1000;
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
		rxd_i <= 1; #1000;
		rxd_i <= 1; #1000;
		rxd_i <= 1; #1000;

		story <= 2;
		reset_i <= 1;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		reset_i <= 0;
		rxd_i <= 0;
		wait(clk_i); wait(~clk_i);

		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{1'b0},{63{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{2'b0},{62{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{3'b0},{61{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{4'b0},{60{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{5'b0},{59{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{6'b0},{58{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{7'b0},{57{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{8'b0},{56{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{9'b0},{55{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{10'b0},{54{1'b1}}}); assert_idle(0);
		rxc_i <= 1; #500; rxc_i <= 0; #500; assert_dat({{11'b0},{53{1'b1}}}); assert_idle(1);

		$display("@I Done.");
		$stop;
	end
endmodule
