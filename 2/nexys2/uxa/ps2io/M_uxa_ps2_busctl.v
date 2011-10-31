`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:		18:59:33 10/30/2011 
// Design Name:		UXA 1A
// Module Name:		M_uxa_ps2_busctl 
// Project Name:		Kestrel-2
// Target Devices:	Nexys2
// Tool versions:
// Description:
//		The PS/2 interface adapter isn't worth anything if you
// 	cannot use a microprocessor to talk to it.  Towards this
// 	goal, we implement a Wishbone-compatible bus interface.
//		This module's purpose deals with Wishbone's control bus
//		signals and bus timing/acknowledgement state machines.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module M_uxa_ps2_busctl(
	input sys_clk_i,
	input sys_reset_i,
	input wb_we_i,
	input wb_stb_i,
	input wb_dat_8_i,
	input wb_dat_9_i,
	output wb_ack_o,
	output rp_inc_o,
	output c_oe_o,
	output d_oe_o
);

	// When reading from the I/O port, we may simply respond to
	// the processor's WB_STB_I signal right away.  Reading from
	// the I/O port takes no action.  It's assumed that other logic
	// maps the q_o outputs of the FIFO module directly to the
	// wb_dat_o outputs.
	assign wb_ack_o = wb_stb_i;

	// When writing, however, we need to be more careful.  First,
	// we need to capture the values of the C and D signals, and
	// perhaps drive the corresponding PS/2 signals low.
	reg c_oe;
	reg d_oe;
	assign c_oe_o = c_oe;
	assign d_oe_o = d_oe;
	
	// We also want to pop the FIFO upon writing to the port.
	// rp_inc_n is the next clock's value for rp_inc.
	reg rp_inc;
	wire rp_inc_n = (~sys_reset_i & wb_stb_i & wb_we_i);
	assign rp_inc_o = rp_inc;

	always @(posedge sys_clk_i) begin
		if (sys_reset_i) begin
			c_oe <= 0;
			d_oe <= 0;
			rp_inc <= 0;
		end else begin
			rp_inc <= rp_inc_n;
			if(wb_stb_i & wb_we_i) begin
				c_oe <= ~wb_dat_9_i;
				d_oe <= ~wb_dat_8_i;
			end
		end
	end
endmodule
