`timescale 1ns / 1ps

// KCP53001 2-to-1 bus arbiter.
//
// This module can be used for two purposes:
// 1. To adapt a Harvard-architecture processor to a Von Neumann-architecture
//    memory bus.  This use-case explains why the input ports are named I-
//    and D-ports.
//
// 2. To support multiple bus masters on a common X-port.  For example, you
//    can have two KCP53000 CPUs, each coupled to a KCP53001 arbiter to
//    yield two Von Neumann processors.  Then, each of these can feed
//    hierarchically into another KCP53001 to merge their combined traffic
//    over a common bus.

module arbiter(
	// I-Port
	input	[63:0]	idat_i,
	input	[63:0]	iadr_i,
	input		iwe_i,
	input		icyc_i,
	input		istb_i,
	input	[1:0]	isiz_i,
	input		isigned_i,
	output		iack_o,
	output	[63:0]	idat_o,

	// D-Port
	input	[63:0]	ddat_i,
	input	[63:0]	dadr_i,
	input		dwe_i,
	input		dcyc_i,
	input		dstb_i,
	input	[1:0]	dsiz_i,
	input		dsigned_i,
	output		dack_o,
	output	[63:0]	ddat_o,

	// X-Port
	output	[63:0]	xdat_o,
	output	[63:0]	xadr_o,
	output		xwe_o,
	output		xcyc_o,
	output		xstb_o,
	output	[1:0]	xsiz_o,
	output		xsigned_o,
	input		xack_i,
	input	[63:0]	xdat_i,

	// Miscellaneous
	input		clk_i,
	input		reset_i
);
	// The reservation bits are used only when both I and D ports request
	// access at the same time.  These help decide who should have priority.
	//
	// Priority is assigned on a first-come, first-served basis.  The
	// exception is when both I and D ports request access during the exact
	// same clock cycle.  In this case, D-port takes priority over I-port.
	//
	// The en_* bits are I/O enables, but also the next states for the
	// reserve_* bits.

	reg reserve_i, reserve_d;

	wire en_i = (~reset_i & icyc_i & ~dcyc_i) |
		    (~reset_i & icyc_i & dcyc_i & reserve_i & ~reserve_d);

	wire en_d = (~reset_i & ~icyc_i & dcyc_i) |
		    (~reset_i & icyc_i & dcyc_i & ~reserve_i) |
		    (~reset_i & icyc_i & dcyc_i & reserve_i & reserve_d);

	assign xdat_o = (en_i ? idat_i : 64'd0) | (en_d ? ddat_i : 64'd0);
	assign xadr_o = (en_i ? iadr_i : 64'd0) | (en_d ? dadr_i : 64'd0);
	assign xwe_o = (en_i & iwe_i) | (en_d & dwe_i);
	assign xcyc_o = (en_i & icyc_i) | (en_d & dcyc_i);
	assign xstb_o = (en_i & istb_i) | (en_d & dstb_i);
	assign xsiz_o = (en_i ? isiz_i : 2'd0) | (en_d ? dsiz_i : 2'd0);
	assign xsigned_o = (en_i & isigned_i) | (en_d & dsigned_i);

	assign iack_o = (en_i & xack_i);
	assign dack_o = (en_d & xack_i);

	assign idat_o = (en_i ? xdat_i : 64'd0);
	assign ddat_o = (en_d ? xdat_i : 64'd0);

	always @(posedge clk_i) begin
		reserve_i <= en_i;
		reserve_d <= en_d;
	end
endmodule

