`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:36:16 10/29/2011
// Design Name:   M_uxa_ps2_shfreg
// Module Name:   /Users/kc5tja/tmp/kestrel/2/nexys2/uxa/ps2io/T_uxa_ps2_shfreg.v
// Project Name:  ps2io
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: M_uxa_ps2_shfreg
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module T_uxa_ps2_shfreg;

	// Inputs
	reg ps2_d_i;
	reg ps2_c_i;
	reg reset_i;
	reg sys_clk_i;

	// Outputs
	wire [7:0] d_o;
	wire frame_o;

	// Instantiate the Unit Under Test (UUT)
	M_uxa_ps2_shfreg uut (
		.ps2_d_i(ps2_d_i), 
		.ps2_c_i(ps2_c_i), 
		.d_o(d_o), 
		.frame_o(frame_o), 
		.reset_i(reset_i), 
		.sys_clk_i(sys_clk_i)
	);

	always begin
		#40  sys_clk_i <= 1;
		#40  sys_clk_i <= 0;
	end

	initial begin
		// Initialize Inputs
		ps2_d_i = 1;
		ps2_c_i = 1;
		reset_i = 1;
		sys_clk_i = 0;
		
		#80 reset_i = 0;

		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		
		#320 ;

		if(d_o != 8'b01100100) begin
			$display("Deserializer failed to grab byte correctly.");
			$stop;
		end
		
		if(frame_o != 1) begin
			$display("Deserializer failed to sync to the PS/2 frame.");
			$stop;
		end
	end
endmodule

