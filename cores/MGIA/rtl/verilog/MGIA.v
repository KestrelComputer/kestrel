`timescale 1ns / 1ps
module MGIA(
	input					CLK_I_50MHZ,
	input					RST_I,
	output				CLK_O_25MHZ,

	output				HSYNC_O,
	output				VSYNC_O,
	output				[2:0]	RED_O,
	output				[2:0]	GRN_O,
	output				[2:1]	BLU_O,
	
	output	[13:1]	MGIA_ADR_O,
	input		[15:0]	MGIA_DAT_I,
	output				MGIA_CYC_O,
	output				MGIA_STB_O,
	input					MGIA_ACK_I
);

	wire				pen;
	wire				clk25mhz;
	wire				vga_refresh;
	wire				vga_fetch;
	wire				odd_line;
	wire	[ 5:0]	sh_adr;
	wire	[15:0]	sh_dat;
	wire	[ 5:0]	vfb_ctr;
	wire	[15:0]	vfb_dat;
	wire				vfb_we;

	assign 	RED_O		= {3{pen}};
	assign 	GRN_O		= {3{pen}};
	assign 	BLU_O		= {2{pen}};

	assign	CLK_O_25MHZ = clk25mhz;
	
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
		.RAM_ADR_O(MGIA_ADR_O),
		.RAM_CYC_O(MGIA_CYC_O),
		.RAM_STB_O(MGIA_STB_O),
		.RAM_ACK_I(MGIA_ACK_I),
		.RAM_DAT_I(MGIA_DAT_I),
		.LB_ADR_O(vfb_ctr),
		.LB_DAT_O(vfb_dat),
		.LB_WE_O(vfb_we)
	);
endmodule
