`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 			Samuel A. Falvo II
// 
// Create Date:    	17:14:59 10/29/2011 
// Design Name: 		UXA 1A
// Module Name:    	M_uxa_ps2_shfreg 
// Project Name: 		Kestrel-2
// Target Devices: 	Nexys2
// Tool versions: 
// Description:
//		Shift register which accepts PS/2 signal input and
// 	deserializes the bitstream into bytes.
//
// 	We discard the parity bit, on the assumption that
//		modern equipment and cabling standards helps ensure
//		proper reception.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module M_uxa_ps2_shfreg(
    input ps2_d_i,
    input ps2_c_i,
    output [7:0] d_o,
    output frame_o,
    input reset_i,
    input sys_clk_i
);

	// The actual shift register sampling data on ps2_d_i.
	reg [10:0] data;

	// We want to sample the PS/2 data line on the rising edge
	// of the PS/2 clock.  We discover this event by ANDing the
	// current ps2_c_i state with its immediately previously
	// sampled value suitably inverted.
	reg curr_ps2_c;
	reg prev_ps2_c;
	wire sample_evt = curr_ps2_c & ~prev_ps2_c;

	// The d_o bus always reflects the state of the shift
	// register's data sub-field.
	assign d_o = data[8:1];

	// We have proper framing when our start bit is 0 and
	// our stop bit is 1.
	reg frame;
	assign frame_o = frame;

	always @(posedge sys_clk_i) begin
		if(!reset_i) begin
			prev_ps2_c <= curr_ps2_c;
			curr_ps2_c <= ps2_c_i;

			if(sample_evt)	data <= {ps2_d_i, data[10:1]};
			else				data <= data;
			
			frame <= data[10] & (~data[0]);
		end else begin
			data <= 11'h7FF;
			frame <= 0;
			prev_ps2_c <= 1;
			curr_ps2_c <= 1;
		end
	end
endmodule
