`timescale 1ns / 1ps

module VRAM16K(
	input					CLK_I,

	output				A_ACK_O,
	input		[13:1]	A_ADR_I,
	input					A_CYC_I,
	output	[15:0]	A_DAT_O,
	input		[15:0]	A_DAT_I,
	input		[1:0]		A_SEL_I,
	input					A_STB_I,
	input					A_WE_I,

	output				B_ACK_O,
	input		[13:1]	B_ADR_I,
	input					B_CYC_I,
	output	[15:0]	B_DAT_O,
	input		[15:0]	B_DAT_I,
	input		[1:0]		B_SEL_I,
	input					B_STB_I,
	input					B_WE_I
);

	reg a_ack;
	reg b_ack;

	assign A_ACK_O = a_ack;
	assign B_ACK_O = b_ack;

	wire a_bus_in_use = A_CYC_I & A_STB_I;
	wire b_bus_in_use = B_CYC_I & B_STB_I;

	always @(posedge CLK_I) begin
		a_ack <= ~a_ack & a_bus_in_use;
		b_ack <= ~b_ack & b_bus_in_use;
	end

	/* Name derived from signals comprising it: CYC, STB, and SEL -- C,S,S -- css. */
	wire a_css0 = a_bus_in_use & A_SEL_I[0];
	wire a_css1 = a_bus_in_use & A_SEL_I[1];

	wire b_css0 = b_bus_in_use & B_SEL_I[0];
	wire b_css1 = b_bus_in_use & B_SEL_I[1];

	// Memory is organized into two "lanes", 0 and 1, representing even and odd memory
	// bytes, respectively.  Each lane, then, contains four "banks" fo 2KB each.  Thus,
	// four 2KB banks times two lanes = 4 * 2KB * 2 = 8 * 2KB = 16KB of RAM.
	wire a_bank0 = A_ADR_I[13:12] == 2'd0;
	wire a_bank1 = A_ADR_I[13:12] == 2'd1;
	wire a_bank2 = A_ADR_I[13:12] == 2'd2;
	wire a_bank3 = A_ADR_I[13:12] == 2'd3;

	wire b_bank0 = B_ADR_I[13:12] == 2'd0;
	wire b_bank1 = B_ADR_I[13:12] == 2'd1;
	wire b_bank2 = B_ADR_I[13:12] == 2'd2;
	wire b_bank3 = B_ADR_I[13:12] == 2'd3;

	wire a_ram0_sel0 = a_bank0 & a_css0;
	wire a_ram1_sel0 = a_bank1 & a_css0;
	wire a_ram2_sel0 = a_bank2 & a_css0;
	wire a_ram3_sel0 = a_bank3 & a_css0;

	wire a_ram0_sel1 = a_bank0 & a_css1;
	wire a_ram1_sel1 = a_bank1 & a_css1;
	wire a_ram2_sel1 = a_bank2 & a_css1;
	wire a_ram3_sel1 = a_bank3 & a_css1;

	wire b_ram0_sel0 = b_bank0 & b_css0;
	wire b_ram1_sel0 = b_bank1 & b_css0;
	wire b_ram2_sel0 = b_bank2 & b_css0;
	wire b_ram3_sel0 = b_bank3 & b_css0;

	wire b_ram0_sel1 = b_bank0 & b_css1;
	wire b_ram1_sel1 = b_bank1 & b_css1;
	wire b_ram2_sel1 = b_bank2 & b_css1;
	wire b_ram3_sel1 = b_bank3 & b_css1;

	wire [7:0] ram00a_dat_o;
	wire [7:0] ram10a_dat_o;
	wire [7:0] ram20a_dat_o;
	wire [7:0] ram30a_dat_o;

	wire [7:0] ram01a_dat_o;
	wire [7:0] ram11a_dat_o;
	wire [7:0] ram21a_dat_o;
	wire [7:0] ram31a_dat_o;

	wire [7:0] al_out = ({8{a_ram0_sel0}} & ram00a_dat_o)
							| ({8{a_ram1_sel0}} & ram10a_dat_o)
							| ({8{a_ram2_sel0}} & ram20a_dat_o)
							| ({8{a_ram3_sel0}} & ram30a_dat_o);

	wire [7:0] ah_out = ({8{a_ram0_sel1}} & ram01a_dat_o)
							| ({8{a_ram1_sel1}} & ram11a_dat_o)
							| ({8{a_ram2_sel1}} & ram21a_dat_o)
							| ({8{a_ram3_sel1}} & ram31a_dat_o);

	wire [15:0] a_dat_out = {ah_out, al_out};
	assign A_DAT_O = a_dat_out;

	wire [7:0] ram00b_dat_o;
	wire [7:0] ram10b_dat_o;
	wire [7:0] ram20b_dat_o;
	wire [7:0] ram30b_dat_o;

	wire [7:0] ram01b_dat_o;
	wire [7:0] ram11b_dat_o;
	wire [7:0] ram21b_dat_o;
	wire [7:0] ram31b_dat_o;

	wire [7:0] bl_out = ({8{b_ram0_sel0}} & ram00b_dat_o)
							| ({8{b_ram1_sel0}} & ram10b_dat_o)
							| ({8{b_ram2_sel0}} & ram20b_dat_o)
							| ({8{b_ram3_sel0}} & ram30b_dat_o);

	wire [7:0] bh_out = ({8{b_ram0_sel1}} & ram01b_dat_o)
							| ({8{b_ram1_sel1}} & ram11b_dat_o)
							| ({8{b_ram2_sel1}} & ram21b_dat_o)
							| ({8{b_ram3_sel1}} & ram31b_dat_o);
	wire [15:0] b_dat_out = {bh_out, bl_out};
	assign B_DAT_O = b_dat_out;

	RAMB16_S9_S9 ram00(
		.WEA(A_WE_I),				.WEB(B_WE_I),
		.ENA(a_ram0_sel0),		.ENB(b_ram0_sel0),
		.SSRA(1'b0),				.SSRB(1'b0),
		.CLKA(CLK_I),				.CLKB(CLK_I),
		.ADDRA(A_ADR_I[11:1]),	.ADDRB(B_ADR_I[11:1]),
		.DIA(A_DAT_I[7:0]),		.DIB(B_DAT_I[7:0]),
		.DIPA(1'b1),				.DIPB(1'b1),
		.DOA(ram00a_dat_o),		.DOB(ram00b_dat_o)
	);

	RAMB16_S9_S9 ram10(
		.WEA(A_WE_I),				.WEB(B_WE_I),
		.ENA(a_ram1_sel0),		.ENB(b_ram1_sel0),
		.SSRA(1'b0),				.SSRB(1'b0),
		.CLKA(CLK_I),				.CLKB(CLK_I),
		.ADDRA(A_ADR_I[11:1]),	.ADDRB(B_ADR_I[11:1]),
		.DIA(A_DAT_I[7:0]),		.DIB(B_DAT_I[7:0]),
		.DIPA(1'b1),				.DIPB(1'b1),
		.DOA(ram10a_dat_o),		.DOB(ram10b_dat_o)
	);

	RAMB16_S9_S9 ram20(
		.WEA(A_WE_I),				.WEB(B_WE_I),
		.ENA(a_ram2_sel0),		.ENB(b_ram2_sel0),
		.SSRA(1'b0),				.SSRB(1'b0),
		.CLKA(CLK_I),				.CLKB(CLK_I),
		.ADDRA(A_ADR_I[11:1]),	.ADDRB(B_ADR_I[11:1]),
		.DIA(A_DAT_I[7:0]),		.DIB(B_DAT_I[7:0]),
		.DIPA(1'b1),				.DIPB(1'b1),
		.DOA(ram20a_dat_o),		.DOB(ram20b_dat_o)
	);

	RAMB16_S9_S9 ram30(
		.WEA(A_WE_I),				.WEB(B_WE_I),
		.ENA(a_ram3_sel0),		.ENB(b_ram3_sel0),
		.SSRA(1'b0),				.SSRB(1'b0),
		.CLKA(CLK_I),				.CLKB(CLK_I),
		.ADDRA(A_ADR_I[11:1]),	.ADDRB(B_ADR_I[11:1]),
		.DIA(A_DAT_I[7:0]),		.DIB(B_DAT_I[7:0]),
		.DIPA(1'b1),				.DIPB(1'b1),
		.DOA(ram30a_dat_o),		.DOB(ram30b_dat_o)
	);

	RAMB16_S9_S9 ram01(
		.WEA(A_WE_I),				.WEB(B_WE_I),
		.ENA(a_ram0_sel1),		.ENB(b_ram0_sel1),
		.SSRA(1'b0),				.SSRB(1'b0),
		.CLKA(CLK_I),				.CLKB(CLK_I),
		.ADDRA(A_ADR_I[11:1]),	.ADDRB(B_ADR_I[11:1]),
		.DIA(A_DAT_I[15:8]),		.DIB(B_DAT_I[15:8]),
		.DIPA(1'b1),				.DIPB(1'b1),
		.DOA(ram01a_dat_o),		.DOB(ram01b_dat_o)
	);

	RAMB16_S9_S9 ram11(
		.WEA(A_WE_I),				.WEB(B_WE_I),
		.ENA(a_ram1_sel1),		.ENB(b_ram1_sel1),
		.SSRA(1'b0),				.SSRB(1'b0),
		.CLKA(CLK_I),				.CLKB(CLK_I),
		.ADDRA(A_ADR_I[11:1]),	.ADDRB(B_ADR_I[11:1]),
		.DIA(A_DAT_I[15:8]),		.DIB(B_DAT_I[15:8]),
		.DIPA(1'b1),				.DIPB(1'b1),
		.DOA(ram11a_dat_o),		.DOB(ram11b_dat_o)
	);

	RAMB16_S9_S9 ram21(
		.WEA(A_WE_I),				.WEB(B_WE_I),
		.ENA(a_ram2_sel1),		.ENB(b_ram2_sel1),
		.SSRA(1'b0),				.SSRB(1'b0),
		.CLKA(CLK_I),				.CLKB(CLK_I),
		.ADDRA(A_ADR_I[11:1]),	.ADDRB(B_ADR_I[11:1]),
		.DIA(A_DAT_I[15:8]),		.DIB(B_DAT_I[15:8]),
		.DIPA(1'b1),				.DIPB(1'b1),
		.DOA(ram21a_dat_o),		.DOB(ram21b_dat_o)
	);

	RAMB16_S9_S9 ram31(
		.WEA(A_WE_I),				.WEB(B_WE_I),
		.ENA(a_ram3_sel1),		.ENB(b_ram3_sel1),
		.SSRA(1'b0),				.SSRB(1'b0),
		.CLKA(CLK_I),				.CLKB(CLK_I),
		.ADDRA(A_ADR_I[11:1]),	.ADDRB(B_ADR_I[11:1]),
		.DIA(A_DAT_I[15:8]),		.DIB(B_DAT_I[15:8]),
		.DIPA(1'b1),				.DIPB(1'b1),
		.DOA(ram31a_dat_o),		.DOB(ram31b_dat_o)
	);
endmodule
