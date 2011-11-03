`timescale 1ns / 1ps
module MGIA(
	input					CLK_I_50MHZ,
	input					RST_I,
	output				HSYNC_O,
	output				VSYNC_O,
	output				[2:0]	RED_O,
	output				[2:0]	GRN_O,
	output				[2:1]	BLU_O
);

	wire				pen;
	wire				clk25mhz;
	wire				vga_refresh;
	wire				vga_fetch;
	wire				odd_line;
	wire	[ 5:0]	sh_adr;
	wire	[15:0]	sh_dat;
	wire	[12:0]	vfr_adr;
	wire	[15:0]	vfr_dat;
	wire				vfr_cyc;
	wire				vfr_stb;
	wire				vfr_ack;
	wire	[ 5:0]	vfb_ctr;
	wire	[15:0]	vfb_dat;
	wire				vfb_we;


	assign	unused	= 12'h000;	// drive unused outputs on Nexys2 board

	assign 	RED_O		= {3{pen}};
	assign 	GRN_O		= {3{pen}};
	assign 	BLU_O		= {2{pen}};

	TIMEBASE tb(
		.RST_I(RST_I),
		.CLK_I_50MHZ(CLK_I_50MHZ),
		.CLK_O_25MHZ(clk25mhz),
		.HSYNC_O(HSYNC_O),
		.VSYNC_O(VSYNC_O),
		.VFEN_O(vga_fetch),
		.VREN_O(vga_refresh),
		.ODD_O(odd_line)
	);

	LINE_BUFFERS lb(
		.CLK_I(clk25mhz),
		.ODD_I(odd_line),
		.F_ADR_I(sh_adr),
		.F_DAT_O(sh_dat),
		.S_ADR_I(vfb_ctr),
		.S_DAT_I(vfb_dat),
		.S_WE_I(vfb_we)
	);
	
	SHIFTER sh(
		.CLK_I_25MHZ(clk25mhz),
		.VREN_I(vga_refresh & !odd_line),
		.F_ADR_O(sh_adr),
		.F_DAT_I(sh_dat),
		.PEN_O(pen)
	);

	VIDEO_FETCHER vf(
		.RST_I(RST_I),
		.CLK_I_25MHZ(clk25mhz),
		.VSYNC_I(VSYNC_O),
		.VFEN_I(vga_fetch & odd_line),
		.RAM_ADR_O(vfr_adr),
		.RAM_CYC_O(vfr_cyc),
		.RAM_STB_O(vfr_stb),
		.RAM_ACK_I(vfr_ack),
		.RAM_DAT_I(vfr_dat),
		.LB_ADR_O(vfb_ctr),
		.LB_DAT_O(vfb_dat),
		.LB_WE_O(vfb_we)
	);

	VRAM vr(
		.RST_I(RST_I),
		.CLK_I(clk25mhz),
		.ADR_I(vfr_adr),
		.CYC_I(vfr_cyc),
		.STB_I(vfr_stb),
		.ACK_O(vfr_ack),
		.DAT_O(vfr_dat)
	);
endmodule
