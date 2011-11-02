`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:57:13 10/31/2011
// Design Name:   M_uxa_ps2
// Module Name:   /Users/kc5tja/tmp/kestrel/2/nexys2/uxa/ps2io/T_uxa_ps2.v
// Project Name:  ps2io
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: M_uxa_ps2
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module T_uxa_ps2;

	// Inputs
	reg ps2_d_i;
	reg ps2_c_i;
	reg sys_clk_i;
	reg sys_reset_i;
	reg io_stb_i;
	reg io_we_i;
	reg [9:8] io_dat_i;

	// Outputs
	wire ps2_c_oe_o;
	wire ps2_d_oe_o;
	wire io_ack_o;
	wire [15:0] io_dat_o;

	// Instantiate the Unit Under Test (UUT)
	M_uxa_ps2 uut (
		.ps2_c_oe_o(ps2_c_oe_o), 
		.ps2_d_oe_o(ps2_d_oe_o), 
		.ps2_d_i(ps2_d_i), 
		.ps2_c_i(ps2_c_i), 
		.sys_clk_i(sys_clk_i), 
		.sys_reset_i(sys_reset_i), 
		.io_ack_o(io_ack_o), 
		.io_stb_i(io_stb_i), 
		.io_we_i(io_we_i), 
		.io_dat_i(io_dat_i), 
		.io_dat_o(io_dat_o)
	);

	always begin
		#40 sys_clk_i <= ~sys_clk_i;
	end

	initial begin
		// Initialize Inputs
		ps2_d_i <= 1;
		ps2_c_i <= 1;
		sys_clk_i <= 0;
		sys_reset_i <= 0;
		io_stb_i <= 0;
		io_we_i <= 0;
		io_dat_i <= 2'b11;
		wait(~sys_clk_i);
		wait(sys_clk_i);

		// Reset the unit.  The bus should be in a well-defined, but strictly idle,
		// state.
		sys_reset_i <= 1;
		wait(~sys_clk_i);
		wait(sys_clk_i);
		sys_reset_i <= 0;
		wait(~sys_clk_i);
		wait(sys_clk_i);
		wait(~sys_clk_i);
		
		if (io_ack_o != 0) begin
			$display("Bus expected to be idle."); $stop;
		end
		
		wait(sys_clk_i);


		// If we read from the PS/2 adapter, we should see
		// bits 13, 12, 11, and 10 always set to zero.
		io_stb_i <= 1;  io_we_i <= 0;
		wait(~sys_clk_i);
		if (io_ack_o != 1) begin
			$display("Single-cycle response time expected when reading"); $stop;
		end
		if (io_dat_o[13] != 0) begin
			$display("When reading, bit 13 of the register should always be zero."); $stop;
		end
		if (io_dat_o[12] != 0) begin
			$display("When reading, bit 12 of the register should always be zero."); $stop;
		end
		if (io_dat_o[11] != 0) begin
			$display("When reading, bit 11 of the register should always be zero."); $stop;
		end
		if (io_dat_o[10] != 0) begin
			$display("When reading, bit 10 of the register should always be zero."); $stop;
		end
		wait(sys_clk_i);


		// If we read from the PS/2 adapter right now, we should see
		// bit 15 (data available) and bit 14 (queue full) flags
		// cleared.
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("Nothing pushed into the queue yet; expected no data available."); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("Nothing pushed into the queue yet; how can it be full?"); $stop;
		end
		wait(sys_clk_i);
		

		// If we send a PS/2 byte into the PS/2 adapter, we should
		// see data is available, but the queue remains non-full.
		// Likewise, the data we just sent should be in the data byte.		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending start bit, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending start bit, F should be clear"); $stop;
		end
		wait(sys_clk_i);

		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending bit 0, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending bit 0, F should be clear"); $stop;
		end
		wait(sys_clk_i);
	
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending bit 1, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending bit 1, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending bit 2, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending bit 2, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending bit 3, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending bit 3, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending bit 4, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending bit 4, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending bit 5, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending bit 5, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending bit 6, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending bit 6, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
		
		#50000  ps2_d_i = 0; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending bit 7, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending bit 7, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		if (io_dat_o[15] != 0) begin
			$display("After sending parity, V should be clear"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending parity, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
		#50000  ps2_d_i = 1; ps2_c_i = 0;
		#50000  ps2_c_i = 1;
		wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		wait(sys_clk_i); wait(~sys_clk_i);
		if (io_dat_o[15] != 1) begin
			$display("After sending stop bit, V should be set"); $stop;
		end
		if (io_dat_o[14] != 0) begin
			$display("After sending stop bit, F should be clear"); $stop;
		end
		wait(sys_clk_i);
		
	end

/*	initial begin
		
		
		// Let's send a bunch of data bytes in, and try reading several
		// times from the PS/2 adapter.  The FIFO shouldn't bump.
		
		// Now let's properly dequeue each byte as we read them in.
		
		// Let's try jiggling each of the output drivers.
		
	end
*/      
endmodule

