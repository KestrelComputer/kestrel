`timescale 1ns / 1ps

module NEXYS2(
	output		ld0_o,

	output		hsync_o,
	output		vsync_o,
	output	[2:0]	red_o,
	output	[2:0]	grn_o,
	output	[2:1]	blu_o,

	output		a0n_o,
	output		a1n_o,
	output		a2n_o,
	output		a3n_o,
	output		k0n_o,
	output		k1n_o,
	output		k2n_o,
	output		k3n_o,
	output		k4n_o,
	output		k5n_o,
	output		k6n_o,
	output		k7n_o,

	input		ps2clk_i,
	input		ps2dat_i,

	input		clk_i,
	input		reset_i
);
	wire		cpu_iack_i;
	wire	[31:0]	cpu_idat_i;
	wire	[63:0]	cpu_iadr_o;
	wire		cpu_istb_o;
	wire		cpu_dack_i;
	wire	[63:0]	cpu_ddat_i;
	wire	[63:0]	cpu_ddat_o;
	wire	[63:0]	cpu_dadr_o;
	wire		cpu_dwe_o;
	wire		cpu_dcyc_o;
	wire		cpu_dstb_o;
	wire	[1:0]	cpu_dsiz_o;
	wire		cpu_dsigned_o;

	wire	[63:0]	arb_dat_o;
	wire	[63:0]	arb_adr_o;
	wire		arb_we_o;
	wire		arb_cyc_o;
	wire		arb_stb_o;
	wire	[1:0]	arb_siz_o;
	wire		arb_signed_o;
	wire		arb_ack_i;
	wire	[63:0]	arb_dat_i;

	wire	[63:0]	s_adr_o;
	wire		s_cyc_o;
	wire		s_signed_o;
	wire		s_siz_o;
	wire		s_stb_o;
	wire		s_we_o;
	wire	[15:0]	s_dat_o;
	wire		s_ack_i;
	wire	[15:0]	s_dat_i;

	wire	[63:0]	f_dat_o;

	wire	[63:1]	wb_adr_o;
	wire	[7:0]	wb_sel_o;
	wire	[63:0]	wb_dat_o;
	wire		wb_cyc_o;
	wire		wb_stb_o;
	wire		wb_we_o;
	wire		wb_ack_i;
	wire	[15:0]	wb_dat_i;

	wire		gpia_ack_o;
	wire	[15:0]	gpia_dat_o;
	wire	[15:0]	gpia_port_o;

	wire		kia_ack_o;
	wire	[7:0]	kia_dat_o;

	wire		rom_ack_o;
	wire	[15:0]	rom_dat_o;

	wire	[15:0]	dsm0_dat_o;
	wire	[15:0]	dsm1_dat_o;
	wire		dsm0_ack_o;
	wire		dsm1_ack_o;

	wire		mgia_ack_i;
	wire	[13:1]	mgia_adr_o;
	wire		mgia_cyc_o;
	wire	[15:0]	mgia_dat_i;
	wire		mgia_stb_o;

	wire	[15:0]	unassigned_dat_o;

	wire		rom_en;
	wire		gpia_en;
	wire		kia_en;
	wire		dsm0_en;
	wire		dsm1_en;
	wire		unassigned_en;	// Default "device"

	wire	[63:0]	kcp53001_idat_o;

	wire		clk25Mhz;

	// CPU

	PolarisCPU kcp53000(
		.fence_o(),
		.trap_o(),
		.cause_o(),
		.mepc_o(),
		.mpie_o(),
		.mie_o(),

		.irq_i(1'b0),

		.iack_i(cpu_iack_i),
		.idat_i(cpu_idat_i),
		.iadr_o(cpu_iadr_o),
		.istb_o(cpu_istb_o),

		.dack_i(cpu_dack_i),
		.ddat_i(cpu_ddat_i),
		.ddat_o(cpu_ddat_o),
		.dadr_o(cpu_dadr_o),
		.dwe_o(cpu_dwe_o),
		.dcyc_o(cpu_dcyc_o),
		.dstb_o(cpu_dstb_o),
		.dsiz_o(cpu_dsiz_o),
		.dsigned_o(cpu_dsigned_o),

		.cadr_o(),
		.coe_o(),
		.cwe_o(),
		.cdat_o(),
		.cvalid_i(1'b0),
		.cdat_i(64'd0),

		.clk_i(clk25Mhz),
		.reset_i(reset_i)
	);

	// Arbiter

	arbiter kcp53001(
		.idat_i(64'd0),
		.iadr_i(cpu_iadr_o),
		.iwe_i(1'b0),
		.icyc_i(cpu_istb_o),
		.istb_i(cpu_istb_o),
		.isiz_i(2'b10),
		.isigned_i(1'b0),
		.iack_o(cpu_iack_i),
		.idat_o(kcp53001_idat_o),

		.ddat_i(cpu_ddat_o),
		.dadr_i(cpu_dadr_o),
		.dwe_i(cpu_dwe_o),
		.dcyc_i(cpu_dcyc_o),
		.dstb_i(cpu_dstb_o),
		.dsiz_i(cpu_dsiz_o),
		.dsigned_i(cpu_dsigned_o),
		.dack_o(cpu_dack_i),
		.ddat_o(cpu_ddat_i),

		.xdat_o(arb_dat_o),
		.xadr_o(arb_adr_o),
		.xwe_o(arb_we_o),
		.xcyc_o(arb_cyc_o),
		.xstb_o(arb_stb_o),
		.xsiz_o(arb_siz_o),
		.xsigned_o(arb_signed_o),
		.xack_i(arb_ack_i),
		.xdat_i(arb_dat_i),

		.clk_i(clk25Mhz),
		.reset_i(reset_i)
	);

	assign cpu_idat_i = kcp53001_idat_o[31:0];

	// 64-bit to 16-bit bridge

	bottleneck kcp53003(
		.m_adr_i(arb_adr_o),
		.m_cyc_i(arb_cyc_o),
		.m_dat_i(arb_dat_o),
		.m_signed_i(arb_signed_o),
		.m_siz_i(arb_siz_o),
		.m_stb_i(arb_stb_o),
		.m_we_i(arb_we_o),
		.m_ack_o(arb_ack_i),
		.m_dat_o(arb_dat_i),
		.m_err_align_o(),

		.s_adr_o(s_adr_o),
		.s_cyc_o(s_cyc_o),
		.s_signed_o(s_signed_o),
		.s_siz_o(s_siz_o),
		.s_stb_o(s_stb_o),
		.s_we_o(s_we_o),
		.s_dat_o(s_dat_o),
		.s_ack_i(s_ack_i),
		.s_dat_i(s_dat_i),

		.clk_i(clk25Mhz),
		.reset_i(reset_i)
	);

	// Wishbone bridge
	//
	// Although this component is suitable for 64-bit
	// wide buses, with clever signal assignments, it can
	// also be used for 16-bit buses as well.

	bridge wb_bridge(
		.f_signed_i(s_signed_o),
		.f_siz_i({1'b0, s_siz_o}),
		.f_adr_i({2'b00, s_adr_o[0]}),
		.f_dat_i({48'd0, s_dat_o}),
		.f_dat_o(f_dat_o),

		.wb_sel_o(wb_sel_o),
		.wb_dat_o(wb_dat_o),
		.wb_dat_i({48'd0, wb_dat_i})
	);

	assign wb_adr_o = s_adr_o[63:1];
	assign wb_cyc_o = s_cyc_o;
	assign wb_stb_o = s_stb_o;
	assign wb_we_o = s_we_o;

	assign s_ack_i = wb_ack_i;
	assign s_dat_i = f_dat_o[15:0];

	// Address Decoder

	assign gpia_en = (wb_adr_o[59:56] == 4'b0001);
	assign kia_en = (wb_adr_o[59:56] == 4'b0010);
	assign dsm0_en = (wb_adr_o[59:56] == 4'b1101) & ~wb_adr_o[14];
	assign dsm1_en = (wb_adr_o[59:56] == 4'b1101) & wb_adr_o[14];
	assign rom_en = (wb_adr_o[59:56] == 4'b1111);

	assign unassigned_en = ~|{gpia_en, kia_en, dsm0_en, dsm1_en, rom_en};

	assign wb_ack_i =
		(gpia_en & gpia_ack_o) |
		(kia_en & kia_ack_o) |
		(dsm0_en & dsm0_ack_o) |
		(dsm1_en & dsm1_ack_o) |
		(rom_en & rom_ack_o) |
		(unassigned_en & wb_stb_o);

	assign wb_dat_i =
		(gpia_en ? gpia_dat_o : 0) |
		(kia_en ? {8'h00, kia_dat_o} : 0) |
		(dsm0_en ? dsm0_dat_o : 0) |
		(dsm1_en ? dsm1_dat_o : 0) |
		(rom_en ? rom_dat_o : 0) |
		(unassigned_en ? unassigned_dat_o : 0);

	// 1MB ROM

	ROM rom(
		.rom_adr_i(wb_adr_o[19:1]),
		.rom_dat_o(rom_dat_o)
	);

	assign rom_ack_o = (rom_en & wb_stb_o);

	// Debug Scratchpad Memory (used for hardware bringup only)
	// Provides 32KB of MGIA-accessible RAM at $0D00000000000000-$0D00000000007FFF.
	// MGIA only accesses $0D00000000000000-$0D00000000003FFF.


	VRAM16K dsm0(
		.CLK_I(clk25Mhz),

		.A_ACK_O(dsm0_ack_o),
		.A_ADR_I(wb_adr_o[13:1]),
		.A_CYC_I(dsm0_en & wb_cyc_o),
		.A_DAT_O(dsm0_dat_o),
		.A_DAT_I(wb_dat_o),
		.A_SEL_I(wb_sel_o),
		.A_STB_I(dsm0_en & wb_stb_o),
		.A_WE_I(wb_we_o),

		.B_ACK_O(mgia_ack_i),
		.B_ADR_I(mgia_adr_o),
		.B_CYC_I(mgia_cyc_o),
		.B_DAT_O(mgia_dat_i),
		.B_DAT_I(16'h0000),
		.B_SEL_I(2'b11),
		.B_STB_I(mgia_stb_o),
		.B_WE_I(1'b0)
	);

	VRAM16K dsm1(
		.CLK_I(clk25Mhz),

		.A_ACK_O(dsm1_ack_o),
		.A_ADR_I(wb_adr_o[13:1]),
		.A_CYC_I(dsm1_en & wb_cyc_o),
		.A_DAT_O(dsm1_dat_o),
		.A_DAT_I(wb_dat_o),
		.A_SEL_I(wb_sel_o),
		.A_STB_I(dsm1_en & wb_stb_o),
		.A_WE_I(wb_we_o),

		.B_ACK_O(),
		.B_ADR_I(14'h0000),
		.B_CYC_I(1'b0),
		.B_DAT_O(),
		.B_DAT_I(16'h0000),
		.B_SEL_I(2'b00),
		.B_STB_I(1'b0),
		.B_WE_I(1'b0)
	);

	// MGIA-1

	MGIA mgia(
		.CLK_I_50MHZ(clk_i),
		.RST_I(reset_i),
		.CLK_O_25MHZ(clk25Mhz),

		.HSYNC_O(hsync_o),
		.VSYNC_O(vsync_o),
		.RED_O(red_o),
		.GRN_O(grn_o),
		.BLU_O(blu_o),

		.MGIA_ADR_O(mgia_adr_o),
		.MGIA_DAT_I(mgia_dat_i),
		.MGIA_CYC_O(mgia_cyc_o),
		.MGIA_STB_O(mgia_stb_o),
		.MGIA_ACK_I(mgia_ack_i)
	);

	// KIA
	
	KIA kia(
		.CLK_I(clk25Mhz),
		.RES_I(reset_i),
		.ADR_I(wb_adr_o[1]),
		.WE_I(wb_we_o),
		.CYC_I(kia_en & wb_cyc_o),
		.STB_I(kia_en & wb_stb_o),
		.ACK_O(kia_ack_o),
		.DAT_O(kia_dat_o),

		.D_I(ps2dat_i),
		.C_I(ps2clk_i)
	);

	// GPIA

	GPIA gpia(
		.RST_I(reset_i),
		.CLK_I(clk25Mhz),
		.ADR_I(wb_adr_o[1]),
		.CYC_I(wb_cyc_o),
		.STB_I(gpia_en & wb_stb_o),
		.WE_I(wb_we_o),
		.DAT_I(wb_dat_o[15:0]),
		.DAT_O(gpia_dat_o),
		.ACK_O(gpia_ack_o),
		.PORT_I(16'h0000),
		.PORT_O(gpia_port_o)
	);

	assign ld0_o = gpia_port_o[0];

	// Unclaimed address handling
	//
	// We set the upper byte to a portion of the address bus, so that
	// debuggers can see crudely where the illegal reference happened.
	// The lowest nybble is set to 4'b1110, which guarantees an illegal
	// instruction trap on the KCP53000.

	assign unassigned_dat_o = {wb_adr_o[63:56], 8'hEE};

assign k0n_o = cpu_iadr_o[1];
assign k1n_o = cpu_iadr_o[2];
assign k2n_o = cpu_iadr_o[3];
assign k3n_o = cpu_iadr_o[4];
assign k4n_o = cpu_iadr_o[5];
assign k5n_o = cpu_iadr_o[6];
assign k6n_o = cpu_iadr_o[7];
assign k7n_o = cpu_iadr_o[8];
assign a0n_o = 0;
assign a1n_o = 1;
assign a2n_o = 1;
assign a3n_o = 1;

endmodule
