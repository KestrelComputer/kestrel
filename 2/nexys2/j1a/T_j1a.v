`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   01:19:39 11/03/2011
// Design Name:   M_j1a
// Module Name:   /Users/kc5tja/tmp/kestrel/2/nexys2/j1a/T_j1a.v
// Project Name:  j1a
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: M_j1a
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module T_j1a;

	// Inputs
	reg sys_res_i;
	reg sys_clk_i;
	reg [15:0] ins_dat_i;
	reg shr_ack_i;

	// Outputs
	wire [15:1] ins_adr_o;
	wire ins_cyc_o;
	wire shr_stb_o;

	// Instantiate the Unit Under Test (UUT)
	M_j1a uut (
		.sys_res_i(sys_res_i), 
		.sys_clk_i(sys_clk_i), 
		.ins_adr_o(ins_adr_o), 
		.ins_dat_i(ins_dat_i), 
		.ins_cyc_o(ins_cyc_o), 
		.shr_stb_o(shr_stb_o), 
		.shr_ack_i(shr_ack_i)
	);

	always begin
		#40 sys_clk_i <= ~sys_clk_i;
	end

	initial begin
		// Initialize Inputs
		sys_res_i <= 0;
		sys_clk_i <= 0;
		ins_dat_i <= 0;
		shr_ack_i <= 0;
		#40;

		//
		// AS A    computer maker
		// I WANT  the J1 to reset to location 0 upon system reset
		// SO THAT the Kestrel-2 will always boot up in a known state.
		//
		wait(sys_clk_i); sys_res_i <= 1;
		wait(~sys_clk_i); wait(sys_clk_i); sys_res_i <= 0;
		wait(~sys_clk_i); wait(sys_clk_i);

		if (ins_adr_o !== 15'h0000) begin
			$display("J1A:0100 PC must reset to 0 after reset"); $stop;
		end		
		
		if (ins_cyc_o !== 1) begin
			$display("J1A:0110 The CPU must assert ins_cyc_o to fetch instructions"); $stop;
		end
		
		if (shr_stb_o !== 1) begin
			$display("J1A:0120 The CPU must strobe the bus to perform a bus transaction"); $stop;
		end
		
		//
		// AS A    motherboard maker
		// I WANT  the J1 to not advance to its next state until SHR_ACK_I is asserted
		// SO THAT slow memories have a chance to catch up.
		//
		wait(~sys_clk_i); wait(sys_clk_i);
		wait(~sys_clk_i); wait(sys_clk_i);
		wait(~sys_clk_i); wait(sys_clk_i);
		wait(~sys_clk_i); wait(sys_clk_i);
		if (ins_adr_o !== 15'h0000) begin
			$display("J1A:0200 PC must not advance if current bus transaction isn't acknowledged"); $stop;
		end		
		
		if (ins_cyc_o !== 1) begin
			$display("J1A:0210 The CPU must continue to hold the bus until it's done with it"); $stop;
		end
		
		if (shr_stb_o !== 1) begin
			$display("J1A:0220 The CPU must strobe the bus to perform a bus transaction"); $stop;
		end
		
		//
		// AS A    motherboard maker
		// I WANT  the processor to continue once its current bus transaction is acknowledged
		// SO THAT slow memories have a chance to catch up.
		//
		wait(~sys_clk_i); wait(sys_clk_i); shr_ack_i <= 1;
		wait(~sys_clk_i); wait(sys_clk_i); shr_ack_i <= 0;
		wait(~sys_clk_i); wait(sys_clk_i);
		if (ins_adr_o !== 15'h0001) begin
			$display("J1A:0300 An acknowledged memory cycle lets the CPU continue."); $stop;
		end
		
		//
		// AS A    microprocessor maker
		// I WANT  the CPU to run full tilt if the bus can keep up
		// SO THAT I can pull maximum performance out if needed.
		//
		shr_ack_i <= 1;
		wait(~sys_clk_i); wait(sys_clk_i); wait(~sys_clk_i);
		if (ins_adr_o !== 15'h0002) begin
			$display("J1A:0400 Pegging ACK should get CPU to run full speed"); $stop;
		end
		wait(sys_clk_i); wait(~sys_clk_i);
		if (ins_adr_o !== 15'h0003) begin
			$display("J1A:0500 Pegging ACK should get CPU to run full speed"); $stop;
		end
		shr_ack_i <= 0;
		wait(sys_clk_i);
	end
      
endmodule

