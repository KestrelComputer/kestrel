`timescale 1ns / 1ps
module TIMEBASE(
	input		RST_I,
	input		CLK_I_50MHZ,
	output	CLK_O_25MHZ,
	output	HSYNC_O,
	output	VSYNC_O,
	output	VREN_O,
	output	VFEN_O,
	output	ODD_O
);

	reg				clk25mhz;
	reg				hsync;
	reg				vsync;
	reg				h_refresh_enable;
	reg				v_refresh_enable;
	reg				v_fetch_enable;

	reg	[9:0]		dotctr;
	reg	[9:0]		dotctr_n;
	reg	[9:0]		linectr;
	reg	[9:0]		linectr_n;

	wire				line_wrap		= dotctr == 794;
	wire 				line_done		= RST_I | line_wrap;
	wire				hsync_assert	= dotctr == 23;
	wire 				hsync_negate	= dotctr == 117;
	wire				frame_done		= RST_I | (linectr == 525);
	wire				vsync_assert	= linectr == 12;
	wire				vsync_negate	= linectr == 14;
	wire				h_refresh_on	= dotctr == 154;
	wire				v_refresh_on	= linectr == 45;
	wire				v_fetch_on		= linectr == 44;
	wire				v_fetch_off		= linectr == 524;

	assign HSYNC_O 		= hsync;
	assign VSYNC_O 		= vsync;
	assign VFEN_O			= h_refresh_enable & v_fetch_enable;
	assign VREN_O			= h_refresh_enable & v_refresh_enable;
	assign CLK_O_25MHZ	= clk25mhz;
	assign ODD_O			= !linectr[0];

	initial begin
		clk25mhz = 0;
		h_refresh_enable = 0;
		v_refresh_enable = 0;
	end

	always @(*) begin
		dotctr_n <= (line_done)? 0 : dotctr+1;
		linectr_n <= (frame_done)? 0 : ((line_wrap)? linectr+1 : linectr);
	end

	always @(posedge CLK_I_50MHZ) begin
		clk25mhz <= ~clk25mhz;
	end
	
	always @(posedge clk25mhz) begin
		dotctr <= (RST_I)? 0 : dotctr_n;
		linectr <= (RST_I)? 0 : linectr_n;

		case({v_fetch_on, v_fetch_off})
			2'b01:	v_fetch_enable <= 0;
			2'b10:	v_fetch_enable <= 1;
			default:	v_fetch_enable <= v_fetch_enable;
		endcase

		case({hsync_assert, hsync_negate})
			2'b01:	hsync <= 1;
			2'b10:	hsync <= 0;
			default:	hsync <= hsync;
		endcase

		case({vsync_assert, vsync_negate})
			2'b01:	vsync <= 1;
			2'b10:	vsync <= 0;
			default:	vsync <= vsync;
		endcase
		
		case({h_refresh_on, line_done})
			2'b01:	h_refresh_enable <= 0;
			2'b10:	h_refresh_enable <= 1;
			default:	h_refresh_enable <= h_refresh_enable;
		endcase

		case({v_refresh_on, frame_done})
			2'b01:	v_refresh_enable <= 0;
			2'b10:	v_refresh_enable <= 1;
			default:	v_refresh_enable <= v_refresh_enable;
		endcase
	end
endmodule
