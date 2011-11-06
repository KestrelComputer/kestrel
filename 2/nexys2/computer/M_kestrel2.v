`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:		12:51:57 11/06/2011 
// Design Name:		Kestrel-2 rev 1A
// Module Name:		M_kestrel2 
// Project Name:		Kestrel-2
// Target Devices:	NEXYS2
// Tool versions: 
// Description: 
//		The Kestrel 2 computer, top-level integration module.
//
// Dependencies: 
//		M_uxa, M_mem, M_j1a
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module M_kestrel2(
	output N2_CA_O,
	output N2_CB_O,
	output N2_CC_O,
	output N2_CD_O,
	output N2_CE_O,
	output N2_CF_O,
	output N2_CG_O,
	output N2_DP_O,
	output N2_A0_O,
	output N2_A1_O,
	output N2_A2_O,
	output N2_A3_O,
	output N2_HSYNC_O,
	output N2_VSYNC_O,
	output [2:0] N2_RED_O,
	output [2:0] N2_GRN_O,
	output [2:1] N2_BLU_O,
	input N2_PS2D_I,
	input N2_PS2C_I,
	input N2_50MHZ_I,
	input N2_RST_I
);

	// Permanently hold the LED outputs in an inactive state,
	// to prevent unnecessary current draw on the part of the
	// FPGA.
	reg a_, b_, c_, d_, e_, f_, g_, dp_, a0_, a1_, a2_, a3_;
	assign N2_CA_O = a_;
	assign N2_CB_O = b_;
	assign N2_CC_O = c_;
	assign N2_CD_O = d_;
	assign N2_CE_O = e_;
	assign N2_CF_O = f_;
	assign N2_CG_O = g_;
	assign N2_DP_O = dp_;
	assign N2_A0_O = a0_;
	assign N2_A1_O = a1_;
	assign N2_A2_O = a2_;
	assign N2_A3_O = a3_;

	initial begin
		a_ <= 1;		e_ <= 1;
		b_ <= 1;		f_ <= 1;
		c_ <= 1;		g_ <= 1;
		d_ <= 1;		dp_ <= 1;
		a0_ <= 1; 	a1_ <= 1;
		a2_ <= 1; 	a3_ <= 1;
	end

	// Each major module has its own set of inputs and
	// outputs.  We declare them here so that the synthesizer
	// has complete knowledge of what to expect before we start
	// routing signals around.
	wire [13:1] j1a_ins_adr_o;
	wire [15:0] j1a_ins_dat_i;
	wire        j1a_ins_cyc_o;
	wire [15:1] j1a_dat_adr_o;
	wire [15:0] j1a_dat_dat_i;
	wire [15:0] j1a_dat_dat_o;
	wire        j1a_dat_cyc_o;
	wire        j1a_dat_we_o;
	wire        j1a_stb_o;
	wire        j1a_ack_i;

	wire [13:1] mem_ins_adr_i;
	wire [13:1] mem_dat_adr_i;
	wire [15:0] mem_ins_dat_o;
	wire [15:0] mem_dat_dat_o;
	wire [15:0] mem_dat_dat_i;
	wire        mem_dat_we_i;
	wire        mem_stb_i;
	wire        mem_ack_o;

	// Instantiate the UXA, which includes the MGIA
	// and PS2IO modules.  This includes video RAM.
	
	// Instantiate the program memory space.
	M_mem mem(
		.ins_adr_i(mem_ins_adr_i),
		.ins_dat_o(mem_ins_dat_o),
		.dat_adr_i(mem_dat_adr_i),
		.dat_dat_o(mem_dat_dat_o),
		.dat_dat_i(mem_dat_dat_i),
		.dat_we_i(mem_dat_we_i),
		.dat_stb_i(mem_stb_i),
		.dat_ack_o(mem_ack_o),
		.dat_clk_i(sys_clk),
		.dat_rst_i(N2_RST_I)
	);

	// Instantiate the J1A microprocessor.
	M_j1a j1a(
		.sys_res_i(N2_RST_I),
		.sys_clk_i(sys_clk),
		.ins_adr_o(j1a_ins_adr_o),
		.ins_dat_i(j1a_ins_dat_i),
		.dat_adr_o(j1a_dat_adr_o),
		.dat_dat_o(j1a_dat_dat_o),
		.dat_dat_i(j1a_dat_dat_i),
		.dat_we_o(j1a_dat_we_o),
		.dat_cyc_o(j1a_dat_cyc_o),
		.ins_cyc_o(j1a_ins_cyc_o),
		.shr_stb_o(j1a_stb_o),
		.shr_ack_i(j1a_ack_i)
	);
	
	// Address decoding logic.
	wire addressing_program_memory = (j1a_dat_adr_o[15:14] == 2'b00);
	wire addressing_video_memory = (j1a_dat_adr_o[15:14] == 2'b10);
	wire addressing_uxa = (j1a_dat_adr_o[15:2] == 14'b11_1111_1111_1111);
	
	// Wishbone requires we route strobe signals based on address
	// decoding state.
	assign mem_stb_i = addressing_program_memory & j1a_stb_o & j1a_dat_cyc_o;
endmodule
