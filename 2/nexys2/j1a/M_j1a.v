`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:			Samuel A. Falvo II
// 
// Create Date:		01:16:55 11/03/2011 
// Design Name:		J1A
// Module Name:		M_j1a 
// Project Name:		Kestrel-2
// Target Devices:	Nexys2
// Tool versions: 
// Description: 
//		Forth-optimized, 16-bit microprocessor created originally
// 	by James Bowman (see http://excamera.com/sphinx/fpga-j1.html).
// 	I re-implemented the processor to incorporate tests and
//		make use of the Wishbone bus.
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module M_j1a(
    input sys_res_i,
    input sys_clk_i,
    output [15:1] ins_adr_o,
    input [15:0] ins_dat_i,
    output ins_cyc_o,
    output shr_stb_o,
    input shr_ack_i
    );

	// The microprocessor needs to fetch instructions from
	// somewhere; the program counter (PC) register tells
	// where.
	reg [15:1] pc;
	assign ins_adr_o = pc;

	// The Wishbone bus requires that we qualify all bus
	// transactions with a CYC_O signal, indicating when
	// the master wants access to the bus.  In the unlikely
	// event that the J1A is used in a multiprocessor
	// scenario on a single bus, this signal is used to
	// arbitrate for bus access.
	reg ins_cyc;
	assign ins_cyc_o = ins_cyc;

	// The J1A sports two different buses: the instruction
	// bus, and the data bus.  The instruction bus fetches
	// data from program space; the data bus fetches or
	// stores data into general memory.  However, both of
	// these buses operate in total lock-step.  Therefore,
	// instead of maintaining two separate STB_O signals
	// (one per bus), we just use a single shared STB_O.
	//
	// As you might expect, a single ACK_I signal is used
	// to acknowledge both buses at once.
	assign shr_stb_o = ins_cyc;

	always @(posedge sys_clk_i) begin
		if (sys_res_i) begin
			pc <= 15'h0000;
			ins_cyc <= 1;
		end else begin
			if (shr_stb_o & shr_ack_i) begin
				pc <= pc+1;
			end
		end
	end
endmodule
