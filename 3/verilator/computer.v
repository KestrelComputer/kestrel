`timescale 1ns / 1ps

// This module implements a subset of the Kestrel-3 computer in a
// configuration reasonable for use with Verilator simulation.

module computer(
	output	[17:1]	ram_adr_i,
	output	[15:0]	ram_dat_i,
	output	[1:0]	ram_sel_i,
	output		ram_wen_i,
	output		ram_oen_i,
	input		ram_ack_o,
	input	[15:0]	ram_dat_o,

	input		ps2_dat_i,
	input		ps2_clk_i,

	input		sd_miso_i,
	input		sd_wp_i,
	input		sd_cd_i,
	output		sd_clk_o,
	output		sd_mosi_o,
	output		sd_cs_o,
	output		sd_led_o,

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
	wire		wb_cyc_o;
	wire		wb_stb_o;
	wire		wb_we_o;
	wire	[7:0]	wb_sel_o;
	wire	[63:0]	wb_dat_o;
	wire	[15:0]	wb_dat_i;

	wire		gpia_ack_o;
	wire	[15:0]	gpia_dat_o;
	wire	[15:0]	gpia_port_o;

	wire		kia_ack_o;
	wire	[7:0]	kia_dat_o;

	wire		rom_ack_o;
	wire	[15:0]	rom_dat_o;

	wire	[15:0]	unassigned_dat_o;

	wire		ram_en;
	wire		rom_en;
	wire		gpia_en;
	wire		kia_en;
	wire		unassigned_en;	// Default "device"

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
		.cvalid_i(1'b0),
		.cdat_o(),
		.cdat_i(64'd0),

		.clk_i(clk_i),
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
		.idat_o(cpu_idat_i),

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

		.clk_i(clk_i),
		.reset_i(reset_i)
	);

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

		.clk_i(clk_i),
		.reset_i(reset_i)
	);

	// Wishbone bridge
	//
	// Although this component is suitable for 64-bit
	// wide buses, with clever signal assignments, it can
	// also be used for 16-bit buses as well.

	bridge wb_bridge(
		.f_signed_i(s_signed_o),
		.f_siz_i(s_siz_o),
		.f_adr_i({2'b00, s_adr_o[0]}),
		.f_dat_i({48'd0, s_dat_o}),
		.f_dat_o(f_dat_o),

		.wb_sel_o(wb_sel_o),
		.wb_dat_o(wb_dat_o),
		.wb_dat_i({48'd0, wb_dat_i})
	);

	assign wb_adr_o = s_adr_o[63:1];

	assign s_dat_i = f_dat_o[15:0];

	// Address Decoder

	assign ram_en = (wb_adr_o[59:56] == 4'b0000);
	assign gpia_en = (wb_adr_o[59:56] == 4'b0001);
	assign kia_en = (wb_adr_o[59:56] == 4'b0010);
	assign rom_en = (wb_adr_o[59:56] == 4'b1111);

	assign unassigned_en = ~|{ram_en, gpia_en, kia_en, rom_en};

	assign wb_ack_i =
		(ram_en & ram_ack_o) |
		(gpia_en & gpia_ack_o) |
		(kia_en & kia_ack_o) |
		(rom_en & rom_ack_o) |
		(unassigned_en & wb_stb_i);

	assign wb_dat_i =
		(ram_en ? ram_dat_o : 0) |
		(gpia_en ? gpia_dat_o : 0) |
		(kia_en ? {8'h00, kia_dat_o} : 0) |
		(rom_en ? rom_dat_o : 0) |
		(unassigned_en ? unassigned_dat_o : 0);

	// 256KB RAM
	//
	// We let Verilator emulate the RAM, since it must also
	// emulate MGIA access to said RAM.  This circuit does
	// not contain a bus arbiter for the RAM just yet.

	assign ram_adr_i = wb_adr[17:1];
	assign ram_dat_i = wb_dat_o[15:0];
	assign ram_sel_i = wb_sel_o[1:0];
	assign ram_wen_i = ~(ram_en & wb_we_o);
	assign ram_oen_i = ~(ram_en & ~wb_we_o);

	// 1MB ROM

	ROM rom(
		.rom_adr_i(wb_adr[19:1]),
		.rom_dat_o(rom_dat_o)
	);

	// GPIA

	GPIA gpia(
		.RST_I(reset_i),
		.CLK_I(clk_i),
		.ADR_I(wb_adr_o[1]),
		.CYC_I(wb_cyc_o),
		.STB_I(gpia_en & wb_stb_o),
		.WE_I(wb_we_o),
		.DAT_I(wb_dat_o[15:0]),
		.DAT_O(gpia_dat_o),
		.ACK_O(gpia_ack_o),
		.PORT_I({13'h0000, sd_miso_i, sd_wp_i, sd_cd_i}),
		.PORT_O(gpia_port_o)
	);

	assign sd_clk_o = gpia_port_o[3];
	assign sd_mosi_o = gpia_port_o[2];
	assign sd_cs_o = gpia_port_o[1];
	assign sd_led_o = gpia_port_o[0];

	// KIA

	KIA kia(
		.ACK_O(kia_ack_o),
		.DAT_O(kia_dat_o),
		.CLK_I(clk_i),
		.RES_I(reset_i),
		.ADR_I(wb_adr_o[1]),
		.WE_I(wb_we_o),
		.CYC_I(kia_en & wb_cyc_o),
		.STB_I(kia_en & wb_stb_o),

		.D_I(ps2_dat_i),
		.C_I(ps2_clk_i)
	);

	// Unclaimed address handling
	//
	// We set the upper byte to a portion of the address bus, so that
	// debuggers can see crudely where the illegal reference happened.
	// The lowest nybble is set to 4'b1110, which guarantees an illegal
	// instruction trap on the KCP53000.

	assign unassigned_dat_o = {wb_adr_o[63:56], 8'hEE};

endmodule

// Fake ROM module

module ROM(
	input	[19:1]	rom_adr_i,
	output	[15:0]	rom_dat_o
);
	reg [15:0] contents[512 * 1024];

	initial begin
		$readmemh("example.bin", contents);
	end

	always @(rom_adr_i) begin
		rom_dat_o <= contents[rom_adr_i];
	end
endmodule

