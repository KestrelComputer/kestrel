`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:29:58 11/07/2011
// Design Name:   M_kestrel2
// Module Name:   /Users/kc5tja/tmp/kestrel/2/nexys2/computer/T_kestrel2.v
// Project Name:  computer
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: M_kestrel2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module T_kestrel2;

	// Inputs
	reg N2_PS2D_I;
	reg N2_PS2C_I;
	reg N2_50MHZ_I;
	reg N2_RST_I;

	// Outputs
	wire N2_CA_O;
	wire N2_CB_O;
	wire N2_CC_O;
	wire N2_CD_O;
	wire N2_CE_O;
	wire N2_CF_O;
	wire N2_CG_O;
	wire N2_DP_O;
	wire N2_A0_O;
	wire N2_A1_O;
	wire N2_A2_O;
	wire N2_A3_O;
	wire N2_HSYNC_O;
	wire N2_VSYNC_O;
	wire [2:0] N2_RED_O;
	wire [2:0] N2_GRN_O;
	wire [2:1] N2_BLU_O;

	// Instantiate the Unit Under Test (UUT)
	M_kestrel2 uut (
		.N2_CA_O(N2_CA_O), 
		.N2_CB_O(N2_CB_O), 
		.N2_CC_O(N2_CC_O), 
		.N2_CD_O(N2_CD_O), 
		.N2_CE_O(N2_CE_O), 
		.N2_CF_O(N2_CF_O), 
		.N2_CG_O(N2_CG_O), 
		.N2_DP_O(N2_DP_O), 
		.N2_A0_O(N2_A0_O), 
		.N2_A1_O(N2_A1_O), 
		.N2_A2_O(N2_A2_O), 
		.N2_A3_O(N2_A3_O), 
		.N2_HSYNC_O(N2_HSYNC_O), 
		.N2_VSYNC_O(N2_VSYNC_O), 
		.N2_RED_O(N2_RED_O), 
		.N2_GRN_O(N2_GRN_O), 
		.N2_BLU_O(N2_BLU_O), 
		.N2_PS2D_I(N2_PS2D_I), 
		.N2_PS2C_I(N2_PS2C_I), 
		.N2_50MHZ_I(N2_50MHZ_I), 
		.N2_RST_I(N2_RST_I)
	);

	always begin
		#20 N2_50MHZ_I <= ~N2_50MHZ_I;
	end

	initial begin
		// Initialize Inputs
		N2_PS2D_I = 0;
		N2_PS2C_I = 0;
		N2_50MHZ_I = 0;
		N2_RST_I = 1;

		// Wait 100 ns for global reset to finish
		#1000;
		N2_RST_I = 0;
        
		// Add stimulus here

	end
      
endmodule

