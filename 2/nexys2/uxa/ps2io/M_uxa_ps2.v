`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 			Samuel A. Falvo II
// 
// Create Date:		19:59:06 10/30/2011 
// Design Name:		UXA 1A
// Module Name:		M_uxa_ps2 
// Project Name:		Kestrel-2
// Target Devices: 	Nexys2
// Tool versions: 
// Description:
//		This top-level module encapsulates one entire PS/2
//		interface adapter.  Instantiate one of these in your
//		design, plus all dependent sub-modules, and you will
//		have a PS/2 interface adapter with a 16-byte FIFO.
//
// Dependencies: 
//		M_uxa_ps2_busctl
//		M_uxa_ps2_fifo
//		M_uxa_ps2_wrtlgc
//		M_uxa_ps2_shfreg
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module M_uxa_ps2(
	// PS/2 port I/O ports
	output				ps2_c_oe_o,
	output				ps2_d_oe_o,
	input					ps2_d_i,
	input					ps2_c_i,

	// Wishbone bus interface
	input					sys_clk_i,
	input					sys_reset_i,
	
	output				io_ack_o,
	input					io_stb_i,
	input					io_we_i,
	input		[9:8]		io_dat_i,
	output	[15:0]	io_dat_o
);

	wire bc_rp_inc_o;
	wire wl_we_o;
	wire wl_ptr_inc_o;
	wire wl_reset_o;
	wire [7:0] sr_d_o;
	wire sr_frame_o;
	wire sr_reset_i = (sys_reset_i | wl_reset_o);

	M_uxa_ps2_busctl busctl (
		.sys_clk_i(sys_clk_i), 
		.sys_reset_i(sys_reset_i), 
		.wb_we_i(io_we_i), 
		.wb_stb_i(io_stb_i), 
		.wb_dat_8_i(io_dat_i[8]), 
		.wb_dat_9_i(io_dat_i[9]),
		.wb_ack_o(io_ack_o), 
		.rp_inc_o(bc_rp_inc_o), 
		.c_oe_o(ps2_c_oe_o), 
		.d_oe_o(ps2_d_oe_o)
	);

	M_uxa_ps2_shfreg shfreg (
		.ps2_d_i(ps2_d_i), 
		.ps2_c_i(ps2_c_i), 
		.d_o(sr_d_o), 
		.frame_o(sr_frame_o), 
		.reset_i(sr_reset_i), 
		.sys_clk_i(sys_clk_i)
	);

	M_uxa_ps2_wrtlgc wrtlgc (
		.frame_i(sr_frame_o), 
		.reset_o(wl_reset_o), 
		.we_o(wl_we_o), 
		.ptr_inc_o(wl_ptr_inc_o), 
		.sys_clk_i(sys_clk_i), 
		.sys_reset_i(sys_reset_i)
	);

	M_uxa_ps2_fifo fifo (
		.d_i(sr_d_o), 
		.we_i(wl_we_o), 
		.wp_inc_i(wl_ptr_inc_o), 
		.q_o(io_dat_o[7:0]), 
		.rp_inc_i(bc_rp_inc_o), 
		.full_o(io_dat_o[14]), 
		.data_available_o(io_dat_o[15]), 
		.sys_clk_i(sys_clk_i), 
		.sys_reset_i(sys_reset_i)
	);

	reg [3:0] zeros;
	assign io_dat_o[13:10] = zeros;
	assign io_dat_o[9] = ps2_c_i;
	assign io_dat_o[8] = ps2_d_i;

	initial begin
		zeros <= 4'b0000;
	end
endmodule
