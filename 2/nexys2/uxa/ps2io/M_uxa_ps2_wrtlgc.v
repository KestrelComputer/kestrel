`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 			Samuel A. Falvo II
// 
// Create Date:		18:16:26 10/30/2011 
// Design Name:		UXA 1A
// Module Name:		M_uxa_ps2_wrtlgc 
// Project Name:		Kestrel-2
// Target Devices:	Nexys2
// Tool versions:
// Description:
//		When the PS/2 deserializer receives a byte, it asserts
// 	its frame_o signal to tell upstream logic that data is now
// 	available for processing.  We want to take that same data
// 	and stuff it into the 16-byte FIFO.  Only after that's done
// 	do we want to clear the deserializer's shift register for
// 	the next incoming byte.
//
// 	All this timing-based behavior depends on a state-machine.
// 	This module implements the state machine necessary to achieve
// 	the above goals.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module M_uxa_ps2_wrtlgc(
	input frame_i,
	output reset_o,
	output we_o,
	output ptr_inc_o,
	input sys_clk_i,
	input sys_reset_i
);

	// We kick things off only when frame_i becomes true.
	// We don't much care about the level of the signal.
	// Thus, we need a historical copy of frame_i to do
	// synchronized edge-detection with.
	reg prev_frame_i;
	
	// To prevent spurious timing, we need to synchronize
	// frame_i against the system clock.
	reg curr_frame_i;

	// We're only concerned with the rising edge of frame_i.
	wire ready = curr_frame_i & ~prev_frame_i;

	// The first thing we want to do when we have data ready
	// is to write the data byte into the FIFO.
	assign we_o = ready;
	
	// After that's done, we want to reset the deserializer,
	// so that we're ready for the next byte.
	reg reset;
	assign reset_o = reset;
	
	// At the same time as we're resetting the deserializer,
	// we can increment the FIFO's write pointer.
	assign ptr_inc_o = reset;
	
	// We use a walking bit counter to implement our state
	// machine.  The timing diagram should look something
	// like this:
	//             _____       _____       _____       ___
	// sys_clk_i  /     \_____/     \_____/     \_____/   
	//                      _______________________
	// frame_i    _________/     \\\\\\\\\\\\\\\\\\\______
	//                           ___________
	// we_o       ______________/           \_____________
	//                                       ___________
	// reset_o    __________________________/           \_
	//                                       ___________
	// ptr_inc_o  __________________________/           \_
	always @(posedge sys_clk_i) begin
		if (sys_reset_i) begin
			curr_frame_i <= 0;
			prev_frame_i <= 0;
			reset <= 0;
		end else begin
			curr_frame_i <= frame_i;
			prev_frame_i <= curr_frame_i;
			reset <= we_o;
		end
	end
endmodule
