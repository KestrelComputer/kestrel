`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   00:45:52 11/03/2011
// Design Name:   MGIA
// Module Name:   /Users/kc5tja/tmp/kestrel/2/nexys2/uxa/mgia/T_uxa_mgia.v
// Project Name:  mgia
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: MGIA
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module T_uxa_mgia;

	// Inputs
	reg CLK_I_50MHZ;
	reg RST_I;

	// Outputs
	wire HSYNC_O;
	wire VSYNC_O;
	wire [2:0] RED_O;
	wire [2:0] GRN_O;
	wire [2:1] BLU_O;

	// Instantiate the Unit Under Test (UUT)
	MGIA uut (
		.CLK_I_50MHZ(CLK_I_50MHZ), 
		.RST_I(RST_I), 
		.HSYNC_O(HSYNC_O), 
		.VSYNC_O(VSYNC_O), 
		.RED_O(RED_O), 
		.GRN_O(GRN_O), 
		.BLU_O(BLU_O)
	);

	always begin
		#10 CLK_I_50MHZ <= ~CLK_I_50MHZ;
	end

	initial begin
		// Initialize Inputs
		CLK_I_50MHZ <= 0;
		RST_I <= 1;
		#100 RST_I <= 0;
	end
      
endmodule

