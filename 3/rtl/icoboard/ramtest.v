`default_nettype none
`timescale 1ns / 1ps

module ramtest(
	input		clk100MHz_i,
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
	reg		clk_i;
	wire	[15:8]	unused;
	wire	[15:0]	leds_raw;
	wire	[15:0]	sram_d_out, sram_d_in;

	reg	[20:1]	counter;
	wire	[19:1]	ramtest_ram_a = {
		counter[20:6], counter[4:1]
	};
	wire		ramtest_ram_we = ~counter[5];

	always @(posedge clk100MHz_i) begin
		clk_i <= clk_i;
		divider <= divider;

		if(reset_i) begin
			divider <= 0;
			clk_i <= ~clk_i;
		end
		else if(divider == 50_000_00) begin
			divider <= 0;
			clk_i <= ~clk_i;
		end
		else begin
			divider <= divider + 1;
		end
	end

	always @(posedge clk_i) begin
		counter <= counter;

		if(reset_i) begin
			counter <= 0;
		end
		else begin
			counter <= counter + 1;
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
	) leds_drivers [7:0] (
		.PACKAGE_PIN(leds),
		.D_OUT_0(leds_raw[7:0])
	);

	ramcon rc(
		.clk_i(clk_i),
		.reset_i(reset_i),

		.cyc_i(1'b1),
		.stb_i(1'b1),
		.we_i(ramtest_ram_we),
		.sel_i(2'b11),
		.adr_i(ramtest_ram_a),
		.dat_i(ramtest_ram_a[16:1]),
		.ack_o(),
		.dat_o(leds_raw),
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

