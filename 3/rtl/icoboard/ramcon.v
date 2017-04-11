`default_nettype none
`timescale 1ns / 1ps

// The RAMCON core exposes an asynchronous, static RAM as a
// synchronous, Wishbone B4 compatible peripheral.
//
// NOTE: This module does not use the chip-enable input of the
// static RAM chip.  It statically hardwires the _CE signal in
// an asserted state.
//
// NOTE: This module does not bind to inout pins.  You must do this
// at the top-level, as how this is done will be FPGA-dependent.
//
// NOTE: This module exposes a STALL_O signal.  However, this
// module currently never stalls the master.  RAMCON will always
// acknowledge a transfer one cycle after it's registered.

module ramcon(
	input		clk_i,
	input		reset_i,

	input		cyc_i,
	input		stb_i,
	input		we_i,
	input	[1:0]	sel_i,
	input	[19:1]	adr_i,
	input	[15:0]	dat_i,
	output		ack_o,
	output	[15:0]	dat_o,
	output		stall_o,

	output		_sram_ce,
	output		_sram_we,
	output		_sram_oe,
	output		_sram_ub,
	output		_sram_lb,
	output	[19:1]	sram_a,
	output	[15:0]	sram_d_out,
	input	[15:0]	sram_d_in
);
	reg		transfer;
	reg	[1:0]	selects;
	reg		write;
	reg	[15:0]	data_in;

	assign		ack_o = transfer;
	wire		sram_we = transfer & write & ~clk_i;
	wire		sram_oe = transfer & ~write & ~clk_i;
	assign		_sram_ce = 0;
	assign		_sram_we = ~sram_we;
	assign		_sram_oe = ~sram_oe;
	assign		_sram_ub = ~selects[1];
	assign		_sram_lb = ~selects[0];
	assign		dat_o = sram_oe ? sram_d_in : 0;
	assign		sram_a = adr_i;
	assign		sram_d_out = data_in;
	assign		stall_o = 0;

	always @(posedge clk_i) begin
		transfer <= cyc_i & stb_i;
		selects <= sel_i;
		write <= we_i;
		data_in <= dat_i;
	end
endmodule

`ifndef SYNTHESIS
module ramcon_tb();
	reg		clk_i, reset_i, cyc_i, stb_i, we_i;
	reg	[1:0]	sel_i;
	reg	[19:1]	adr_i;
	reg	[15:0]	dat_i;
	wire		ack_o;
	wire		_sram_we, _sram_oe, _sram_ub, _sram_lb;
	wire	[15:0]	dat_o, sram_d_out;
	wire	[19:1]	sram_a;

	ramcon rc(
		.clk_i(clk_i),
		.reset_i(reset_i),
		.cyc_i(cyc_i),
		.stb_i(stb_i),
		.we_i(we_i),
		.sel_i(sel_i),
		.adr_i(adr_i),
		.ack_o(ack_o),
		.dat_o(dat_o),
		.dat_i(dat_i),
		._sram_we(_sram_we),
		._sram_oe(_sram_oe),
		._sram_ub(_sram_ub),
		._sram_lb(_sram_lb),
		.sram_a(sram_a),
		.sram_d_in(16'hF00D),
		.sram_d_out(sram_d_out)
	);

	always begin
		#5 clk_i <= ~clk_i;
	end

	always begin
		#20 adr_i <= adr_i + 1;
	end

	initial begin
		$dumpfile("ramcon.vcd");
		$dumpvars;

		{clk_i, reset_i, cyc_i, stb_i, we_i, sel_i, adr_i, dat_i} = 0;
		wait(~clk_i); wait(clk_i);

		reset_i <= 1;
		wait(~clk_i); wait(clk_i);

		reset_i <= 0;
		wait(~clk_i); wait(clk_i);
		
		cyc_i <= 1;
		stb_i <= 1;
		wait(~clk_i); wait(clk_i);
		stb_i <= 0;
		wait(~clk_i); wait(clk_i);

		stb_i <= 1;
		wait(~clk_i); wait(clk_i);
		sel_i <= 2'b01;
		wait(~clk_i); wait(clk_i);
		sel_i <= 2'b10;
		wait(~clk_i); wait(clk_i);
		sel_i <= 2'b11;
		stb_i <= 0;
		wait(~clk_i); wait(clk_i);
		cyc_i <= 0;
		sel_i <= 0;

		#100;
		$stop;
	end
endmodule
`endif

