`default_nettype none
`timescale 1ns / 1ps

module ramtest(
	input		clk_i,
	input		reset_i,

	output		_sram_ce,
	output		_sram_we,
	output		_sram_oe,
	output		_sram_ub,
	output		_sram_lb,
	output	[19:1]	sram_a,
	inout	[15:0]	sram_d,

	output	[7:0]	leds
);
	reg	[26:0]	divider;
	wire	[15:8]	unused;
	wire	[7:0]	leds_raw;
	wire	[15:0]	sram_d_out, sram_d_in;

	reg	[20:1]	counter;
	wire	[19:1]	ramtest_ram_a = {
		counter[20:5], counter[3:0]
	};
	wire		ramtest_ram_we = counter[4];

	always @(posedge clk_i) begin
		if(reset_i) begin
			counter <= 0;
			divider <= 0;
		end
		else if(divider == 27'd100000000) begin
			counter <= counter + |1;
			divider <= 0;
		end
		else begin
			divider <= divider + |1;
		end
	end

	SB_IO #(
		.PIN_TYPE(6'b1010_01),
		.PULLUP(1'b0)
	) sram_io [15:0] (
		.PACKAGE_PIN(sram_d),
		.OUTPUT_ENABLE(~_sram_we),
		.D_OUT_0(sram_d_out),
		.D_IN_0(sram_d_in)
	);

	SB_IO #(
		.PIN_TYPE(6'b0110_01),
		.PULLUP(1'b0)
	) led_drivers [7:0] (
		.PACKAGE_PIN(leds),
		.D_OUT_0(leds_raw)
	);

	ramcon rc(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.cyc_i(1'b1),
		.stb_i(1'b1),
		.we_i(ramtest_ram_we),
		.sel_i(2'b11),
		.adr_i(ramtest_ram_a),
		.dat_i(ramtest_ram_a[15:0]),
		.ack_o(),
		.dat_o({unused, leds_raw}),
		.stall_o(),

		._sram_ce(_sram_ce),
		._sram_we(_sram_we),
		._sram_oe(_sram_oe),
		._sram_ub(_sram_ub),
		._sram_lb(_sram_lb),
		.sram_a(sram_a),
		.sram_d_out(sram_d_out),
		.sram_d_in(sram_d_in)
	);
endmodule

