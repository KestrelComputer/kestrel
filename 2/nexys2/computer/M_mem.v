`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:			Samuel A. Falvo II
// 
// Create Date:		13:06:23 11/06/2011 
// Design Name:		Program Memory
// Module Name:		M_mem 
// Project Name:		Kestrel-2
// Target Devices:	NEXYS2
// Tool versions:
// Description:
//		Program memory from $0000-$3FFF, which also holds the
//		bootstrap code.  This is the closest thing the Kestrel-2
//		has to having firmware.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module M_mem(
	input  [13:1] ins_adr_i,
	output [15:0] ins_dat_o,
	input  [13:1] dat_adr_i,
	output [15:0] dat_dat_o,
	input  [15:0] dat_dat_i,
	input         dat_we_i,
	input         dat_stb_i,
	output        dat_ack_o,
	input         dat_clk_i,
	input         dat_rst_i
);

	// Asynchronous address decoding logic.  Note that we
	// need separate logic for the instruction and data
	// buses.
	wire ien0 = (ins_adr_i[13:11] == 3'b000);
	wire ien1 = (ins_adr_i[13:11] == 3'b001);
	wire ien2 = (ins_adr_i[13:11] == 3'b010);
	wire ien3 = (ins_adr_i[13:11] == 3'b011);
	wire ien4 = (ins_adr_i[13:11] == 3'b100);
	wire ien5 = (ins_adr_i[13:11] == 3'b101);
	wire ien6 = (ins_adr_i[13:11] == 3'b110);
	wire ien7 = (ins_adr_i[13:11] == 3'b111);

	wire den0 = (dat_adr_i[13:11] == 3'b000) & dat_stb_i;
	wire den1 = (dat_adr_i[13:11] == 3'b001) & dat_stb_i;
	wire den2 = (dat_adr_i[13:11] == 3'b010) & dat_stb_i;
	wire den3 = (dat_adr_i[13:11] == 3'b011) & dat_stb_i;
	wire den4 = (dat_adr_i[13:11] == 3'b100) & dat_stb_i;
	wire den5 = (dat_adr_i[13:11] == 3'b101) & dat_stb_i;
	wire den6 = (dat_adr_i[13:11] == 3'b110) & dat_stb_i;
	wire den7 = (dat_adr_i[13:11] == 3'b111) & dat_stb_i;

	wire [15:0] iq0, iq1, iq2, iq3, iq4, iq5, iq6, iq7;
	wire [15:0] dq0, dq1, dq2, dq3, dq4, dq5, dq6, dq7;

	reg [15:0] ins_dat;
	reg [15:0] dat_dat;
	assign ins_dat_o = ins_dat;
	assign dat_dat_o = dat_dat;

	// Gives processor the illusion that it's talking to an
	// asynchronous RAM at 12.5MHz.  This implies that the
	// data clock must run at 25.0MHz.
	reg dat_ack;
	assign dat_ack_o = dat_ack;
	
	always @(posedge dat_clk_i) begin
		dat_ack <= (~dat_ack & dat_stb_i & ~dat_rst_i);
	end

	// RAM addressing logic
	always @* begin
		case (ins_adr_i[13:11])
			3'b000:	ins_dat <= iq0;
			3'b001:	ins_dat <= iq1;
			3'b010:	ins_dat <= iq2;
			3'b011:	ins_dat <= iq3;
			3'b100:	ins_dat <= iq4;
			3'b101:	ins_dat <= iq5;
			3'b110:	ins_dat <= iq6;
			3'b111:	ins_dat <= iq7;
			default:	ins_dat <= 16'hxxxx;
		endcase

		case(dat_adr_i[13:11])
			3'b000:  dat_dat <= dq0;
			3'b001:  dat_dat <= dq1;
			3'b010:  dat_dat <= dq2;
			3'b011:  dat_dat <= dq3;
			3'b100:  dat_dat <= dq4;
			3'b101:  dat_dat <= dq5;
			3'b110:  dat_dat <= dq6;
			3'b111:  dat_dat <= dq7;
			default: dat_dat <= 16'hxxxx;
		endcase
	end

	// RAM instances themselves.  Eight instances
	// times 2KB each equals 16KB total program memory.
	RAMB16_S18_S18 ram00_07(
		.WEA(1'b0),						.WEB(dat_we_i),
		.ENA(ien0),						.ENB(den0),
		.SSRA(1'b0),					.SSRB(1'b0),
		.CLKA(dat_clk_i),				.CLKB(dat_clk_i),
		.ADDRA(ins_adr_i[10:1]),	.ADDRB(dat_adr_i[10:1]),
		.DIA(16'h0000),				.DIB(dat_dat_i),
		.DOA(iq0),						.DOB(dq0),
		.DIPA(0), 						.DIPB(0)
	);

	RAMB16_S18_S18 ram08_0F(
		.WEA(1'b0),						.WEB(dat_we_i),
		.ENA(ien1),						.ENB(den1),
		.SSRA(1'b0),					.SSRB(1'b0),
		.CLKA(dat_clk_i),				.CLKB(dat_clk_i),
		.ADDRA(ins_adr_i[10:1]),	.ADDRB(dat_adr_i[10:1]),
		.DIA(16'h0000),				.DIB(dat_dat_i),
		.DOA(iq1),						.DOB(dq1),
		.DIPA(0), 						.DIPB(0)
	);

	RAMB16_S18_S18 ram10_17(
		.WEA(1'b0),						.WEB(dat_we_i),
		.ENA(ien2),						.ENB(den2),
		.SSRA(1'b0),					.SSRB(1'b0),
		.CLKA(dat_clk_i),				.CLKB(dat_clk_i),
		.ADDRA(ins_adr_i[10:1]),	.ADDRB(dat_adr_i[10:1]),
		.DIA(16'h0000),				.DIB(dat_dat_i),
		.DOA(iq2),						.DOB(dq2),
		.DIPA(0), 						.DIPB(0)
	);

	RAMB16_S18_S18 ram18_1F(
		.WEA(1'b0),						.WEB(dat_we_i),
		.ENA(ien3),						.ENB(den3),
		.SSRA(1'b0),					.SSRB(1'b0),
		.CLKA(dat_clk_i),				.CLKB(dat_clk_i),
		.ADDRA(ins_adr_i[10:1]),	.ADDRB(dat_adr_i[10:1]),
		.DIA(16'h0000),				.DIB(dat_dat_i),
		.DOA(iq3),						.DOB(dq3),
		.DIPA(0), 						.DIPB(0)
	);

	RAMB16_S18_S18 ram20_27(
		.WEA(1'b0),						.WEB(dat_we_i),
		.ENA(ien4),						.ENB(den4),
		.SSRA(1'b0),					.SSRB(1'b0),
		.CLKA(dat_clk_i),				.CLKB(dat_clk_i),
		.ADDRA(ins_adr_i[10:1]),	.ADDRB(dat_adr_i[10:1]),
		.DIA(16'h0000),				.DIB(dat_dat_i),
		.DOA(iq4),						.DOB(dq4),
		.DIPA(0), 						.DIPB(0)
	);

	RAMB16_S18_S18 ram28_2F(
		.WEA(1'b0),						.WEB(dat_we_i),
		.ENA(ien5),						.ENB(den5),
		.SSRA(1'b0),					.SSRB(1'b0),
		.CLKA(dat_clk_i),				.CLKB(dat_clk_i),
		.ADDRA(ins_adr_i[10:1]),	.ADDRB(dat_adr_i[10:1]),
		.DIA(16'h0000),				.DIB(dat_dat_i),
		.DOA(iq5),						.DOB(dq5),
		.DIPA(0), 						.DIPB(0)
	);

	RAMB16_S18_S18 ram30_37(
		.WEA(1'b0),						.WEB(dat_we_i),
		.ENA(ien6),						.ENB(den6),
		.SSRA(1'b0),					.SSRB(1'b0),
		.CLKA(dat_clk_i),				.CLKB(dat_clk_i),
		.ADDRA(ins_adr_i[10:1]),	.ADDRB(dat_adr_i[10:1]),
		.DIA(16'h0000),				.DIB(dat_dat_i),
		.DOA(iq6),						.DOB(dq6),
		.DIPA(0), 						.DIPB(0)
	);

	RAMB16_S18_S18 ram38_3F(
		.WEA(1'b0),						.WEB(dat_we_i),
		.ENA(ien7),						.ENB(den7),
		.SSRA(1'b0),					.SSRB(1'b0),
		.CLKA(dat_clk_i),				.CLKB(dat_clk_i),
		.ADDRA(ins_adr_i[10:1]),	.ADDRB(dat_adr_i[10:1]),
		.DIA(16'h0000),				.DIB(dat_dat_i),
		.DOA(iq7),						.DOB(dq7),
		.DIPA(0), 						.DIPB(0)
	);
endmodule
