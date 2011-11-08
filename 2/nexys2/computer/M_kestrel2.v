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
	reg  [15:0] j1a_dat_dat_i;
	wire [15:0] j1a_dat_dat_o;
	wire        j1a_dat_cyc_o;
	wire        j1a_dat_we_o;
	wire        j1a_stb_o;
	reg         j1a_ack_i;

	wire			pm_dat_ack_o;
	wire			pm_ins_ack_o;
	wire [15:0]	pm_dat_o;
	reg 			pm_dat_stb;

	wire [15:0]	vm_dat_o;
	reg			vm_dat_stb;
	wire			vm_dat_ack_o;

	wire [13:1]	mgia_adr_o;
	wire [15:0]	mgia_dat_i;
	wire			mgia_cyc_o;
	wire			mgia_stb_o;
	wire			mgia_ack_i;
	wire			sys_clk;

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

	wire data_access = ~N2_RST_I & j1a_stb_o & j1a_dat_cyc_o;
	wire addressing_prg_mem = j1a_dat_adr_o[15:14] == 2'b00;
	wire addressing_vid_mem = j1a_dat_adr_o[15:14] == 2'b10;

	always @* begin
		// When fetching data from various resources, the CPU will
		// need to select which output data bus to read from.
		if (addressing_prg_mem)
			j1a_dat_dat_i <= pm_dat_o;
		else if (addressing_vid_mem)
			j1a_dat_dat_i <= vm_dat_o;
//		else if (addressing_kbd_ps2)
//			j1a_dat_dat_i <= kbd_dat_o;
		else
			j1a_dat_dat_i <= 16'hxxxx;
			
		// Peripherals won't know to drive their buses, however,
		// unless told to do so by asserting the appropriate
		// data strobes.
		pm_dat_stb <= data_access & addressing_prg_mem;
		vm_dat_stb <= data_access & addressing_vid_mem;

		// Since the Kestrel-2 lacks multi-master support,
		// we can get by with simply ORing all the acknowledgements
		// together.
		j1a_ack_i <= pm_ins_ack_o | pm_dat_ack_o | vm_dat_ack_o;
	end

	// Program Memory ($0000-$3FFF)
	M_mem pm(
		.ins_adr_i(j1a_ins_adr_o),
		.ins_dat_o(j1a_ins_dat_i),
		.ins_cyc_i(j1a_ins_cyc_o),
		.ins_stb_i(j1a_stb_o),
		.ins_ack_o(pm_ins_ack_o),

		.dat_adr_i(j1a_dat_adr_o[13:1]),
		.dat_dat_o(pm_dat_o),
		.dat_dat_i(j1a_dat_dat_o),
		.dat_we_i(j1a_dat_we_o),
		.dat_cyc_i(j1a_dat_cyc_o),
		.dat_stb_i(pm_dat_stb),
		.dat_ack_o(pm_dat_ack_o),

		.sys_clk_i(sys_clk),
		.sys_rst_i(N2_RST_I)
	);
	
	// Video Memory ($8000-$BFFF)
	M_mem vm(
		.ins_adr_i(mgia_adr_o),
		.ins_dat_o(mgia_dat_i),
		.ins_cyc_i(mgia_cyc_o),
		.ins_stb_i(mgia_stb_o),
		.ins_ack_o(mgia_ack_i),
		
		.dat_adr_i(j1a_dat_adr_o[13:1]),
		.dat_dat_o(vm_dat_o),
		.dat_dat_i(j1a_dat_dat_o),
		.dat_we_i(j1a_dat_we_o),
		.dat_cyc_i(j1a_dat_cyc_o),
		.dat_stb_i(vm_dat_stb),
		.dat_ack_o(vm_dat_ack_o),
		
		.sys_clk_i(sys_clk),
		.sys_rst_i(N2_RST_I)
	);

	// Monochrome Graphics Interface Adapter
	M_uxa_mgia mgia(
		.CLK_I_50MHZ(N2_50MHZ_I),
		.RST_I(N2_RST_I),
		.CLK_O_25MHZ(sys_clk),

		.HSYNC_O(N2_HSYNC_O),
		.VSYNC_O(N2_VSYNC_O),
		.RED_O(N2_RED_O),
		.GRN_O(N2_GRN_O),
		.BLU_O(N2_BLU_O),
	
		.MGIA_ADR_O(mgia_adr_o),
		.MGIA_DAT_I(mgia_dat_i),
		.MGIA_CYC_O(mgia_cyc_o),
		.MGIA_STB_O(mgia_stb_o),
		.MGIA_ACK_I(mgia_ack_i)
	);

	// Keyboard PS2IO ($FFFE)
	
	// Video RAM static image (at boot-time)
	defparam
vm.ram00_07.INIT_3F = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_3E = 256'h55555555555555555555555555555555AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_3D = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_3C = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_3B = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_3A = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_39 = 256'h55555555555555555555000000000000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_38 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_37 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA000C228AF1C2,
vm.ram00_07.INIT_36 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_35 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_34 = 256'h55555555555555555555010C228A8882AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_33 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_32 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA019822FA8882,
vm.ram00_07.INIT_31 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_30 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_2F = 256'h55555555555555555555C1D82A53F082AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_2E = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_2D = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA21F02A528882,
vm.ram00_07.INIT_2C = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_2B = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_2A = 256'h5555555555555555555521FC36228882AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_29 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_28 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAC1F8A223F1CF,
vm.ram00_07.INIT_27 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_26 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_25 = 256'h5555555555555555555501F000000000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_24 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_23 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE1E0A0FB7228,
vm.ram00_07.INIT_22 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_21 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_20 = 256'h5555555555555555555501C0A0828A28AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_1F = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_1E = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0180A0820A28,
vm.ram00_07.INIT_1D = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_1C = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_1B = 256'h555555555555555555558100BC8373EAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_1A = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_19 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA0000A282822A,
vm.ram00_07.INIT_18 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_17 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_16 = 256'h555555555555555555550000A282894DAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_15 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_14 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE000BC837088,
vm.ram00_07.INIT_13 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_12 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_11 = 256'h55555555555555555555000000000000AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_10 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_0F = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAEF88088B8BE7,
vm.ram00_07.INIT_0E = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_0D = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_0C = 256'h55555555555555555555080088929208AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_0B = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_0A = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA080888A2A200,
vm.ram00_07.INIT_09 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_08 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_07 = 256'h55555555555555555555880808F3C387AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_06 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_05 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA081C088AA208,
vm.ram00_07.INIT_04 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_03 = 256'h5555555555555555555555555555555555555555555555555555555555555555,
vm.ram00_07.INIT_02 = 256'h55555555555555555555081C888A9208AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_01 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA,
vm.ram00_07.INIT_00 = 256'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAE8083EF38BE7;

	// System Firmware

defparam
pm.ram00_07.INIT_00 = 256'h00040081001c001f00026103610360206600ffff660040016600ffff7c0c0002;

endmodule
