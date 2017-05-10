`timescale 1ns / 1ps

// KCP53002 Furcula to Wishbone bus bridge
//
// Note that Furcula is, in reality, a slight modification of Wishbone.
// Since these two interconnects share so many signals in common, the
// interface to the bridge is kept very small.

module bridge(
	// FURCULA BUS
	input		f_signed_i,
	input	[1:0]	f_siz_i,
	input	[2:0]	f_adr_i,
	input	[63:0]	f_dat_i,
	output	[63:0]	f_dat_o,

	// WISHBONE BUS
	output	[7:0]	wb_sel_o,
	output	[63:0]	wb_dat_o,
	input	[63:0]	wb_dat_i
);
	// Wishbone SEL_O signal generation.

	wire size_byte = (f_siz_i == 2'b00);
	wire size_hword = (f_siz_i == 2'b01);
	wire size_word = (f_siz_i == 2'b10);
	wire size_dword = (f_siz_i == 2'b11);

	wire ab7 = f_adr_i[2:0] == 3'b111;
	wire ab6 = f_adr_i[2:0] == 3'b110;
	wire ab5 = f_adr_i[2:0] == 3'b101;
	wire ab4 = f_adr_i[2:0] == 3'b100;
	wire ab3 = f_adr_i[2:0] == 3'b011;
	wire ab2 = f_adr_i[2:0] == 3'b010;
	wire ab1 = f_adr_i[2:0] == 3'b001;
	wire ab0 = f_adr_i[2:0] == 3'b000;

	wire ah3 = f_adr_i[2:1] == 2'b11;
	wire ah2 = f_adr_i[2:1] == 2'b10;
	wire ah1 = f_adr_i[2:1] == 2'b01;
	wire ah0 = f_adr_i[2:1] == 2'b00;

	wire aw1 = f_adr_i[2] == 1'b1;
	wire aw0 = f_adr_i[2] == 1'b0;

	wire den = size_dword;
	wire wen1 = size_word & aw1;
	wire wen0 = size_word & aw0;
	wire hen3 = size_hword & ah3;
	wire hen2 = size_hword & ah2;
	wire hen1 = size_hword & ah1;
	wire hen0 = size_hword & ah0;
	wire ben7 = size_byte & ab7;
	wire ben6 = size_byte & ab6;
	wire ben5 = size_byte & ab5;
	wire ben4 = size_byte & ab4;
	wire ben3 = size_byte & ab3;
	wire ben2 = size_byte & ab2;
	wire ben1 = size_byte & ab1;
	wire ben0 = size_byte & ab0;

	wire sel7 = den | wen1 | hen3 | ben7;
	wire sel6 = den | wen1 | hen3 | ben6;
	wire sel5 = den | wen1 | hen2 | ben5;
	wire sel4 = den | wen1 | hen2 | ben4;
	wire sel3 = den | wen0 | hen1 | ben3;
	wire sel2 = den | wen0 | hen1 | ben2;
	wire sel1 = den | wen0 | hen0 | ben1;
	wire sel0 = den | wen0 | hen0 | ben0;

	assign wb_sel_o = {sel7, sel6, sel5, sel4, sel3, sel2, sel1, sel0};

	// Furcula-to-Wishbone Data Routing

	wire [7:0] od7 =
		(size_byte ? f_dat_i[7:0] : 0) |
		(size_hword ? f_dat_i[15:8] : 0) |
		(size_word ? f_dat_i[31:24] : 0) |
		(size_dword ? f_dat_i[63:56] : 0);

	wire [7:0] od6 =
		(size_byte ? f_dat_i[7:0] : 0) |
		(size_hword ? f_dat_i[7:0] : 0) |
		(size_word ? f_dat_i[23:16] : 0) |
		(size_dword ? f_dat_i[55:48] : 0);

	wire [7:0] od5 =
		(size_byte ? f_dat_i[7:0] : 0) |
		(size_hword ? f_dat_i[15:8] : 0) |
		(size_word ? f_dat_i[15:8] : 0) |
		(size_dword ? f_dat_i[47:40] : 0);

	wire [7:0] od4 =
		(size_byte ? f_dat_i[7:0] : 0) |
		(size_hword ? f_dat_i[7:0] : 0) |
		(size_word ? f_dat_i[7:0] : 0) |
		(size_dword ? f_dat_i[39:32] : 0);

	wire [7:0] od3 =
		(size_byte ? f_dat_i[7:0] : 0) |
		(size_hword ? f_dat_i[15:8] : 0) |
		(size_word ? f_dat_i[31:24] : 0) |
		(size_dword ? f_dat_i[31:24] : 0);

	wire [7:0] od2 =
		(size_byte ? f_dat_i[7:0] : 0) |
		(size_hword ? f_dat_i[7:0] : 0) |
		(size_word ? f_dat_i[23:16] : 0) |
		(size_dword ? f_dat_i[23:16] : 0);

	wire [7:0] od1 =
		(size_byte ? f_dat_i[7:0] : 0) |
		(size_hword ? f_dat_i[15:8] : 0) |
		(size_word ? f_dat_i[15:8] : 0) |
		(size_dword ? f_dat_i[15:8] : 0);

	wire [7:0] od0 = f_dat_i[7:0];

	assign wb_dat_o = {od7, od6, od5, od4, od3, od2, od1, od0};

	// Wishbone to Furcula Data Routing

	wire [31:0] id2 =
			(wen1 ? wb_dat_i[63:32] : 0) |
			(wen0 ? wb_dat_i[31:0] : 0);
	wire [15:0] id1 =
			(hen3 ? wb_dat_i[63:48] : 0) |
			(hen2 ? wb_dat_i[47:32] : 0) |
			(hen1 ? wb_dat_i[31:16] : 0) |
			(hen0 ? wb_dat_i[15:0] : 0);
	wire [7:0] id0 =
			(ben7 ? wb_dat_i[63:56] : 0) |
			(ben6 ? wb_dat_i[55:48] : 0) |
			(ben5 ? wb_dat_i[47:40] : 0) |
			(ben4 ? wb_dat_i[39:32] : 0) |
			(ben3 ? wb_dat_i[31:24] : 0) |
			(ben2 ? wb_dat_i[23:16] : 0) |
			(ben1 ? wb_dat_i[15:8] : 0) |
			(ben0 ? wb_dat_i[7:0] : 0);
	wire [63:32] id2s = (f_signed_i ? {32{id2[31]}} : 32'd0);
	wire [63:16] id1s = (f_signed_i ? {48{id1[15]}} : 48'd0);
	wire [63:8] id0s = (f_signed_i ? {56{id0[7]}} : 56'd0);

	assign f_dat_o =
		(size_dword ? wb_dat_i : 0) |
		(size_word ? {id2s, id2} : 0) |
		(size_hword ? {id1s, id1} : 0) |
		(size_byte ? {id0s, id0} : 0);
endmodule

