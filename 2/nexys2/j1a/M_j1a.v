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
    output [13:1] ins_adr_o,
    input [15:0] ins_dat_i,
	 output [15:1] dat_adr_o,
	 output [15:0] dat_dat_o,
	 input [15:0] dat_dat_i,
	 output dat_we_o,
	 output dat_cyc_o,
    output ins_cyc_o,
    output shr_stb_o,
    input shr_ack_i
    );

	// The asynchronous logic works to compute the processor's
	// next state.  (Part 1)
	wire is_alu = (ins_dat_i[15:13] === 3'b011);
	wire is_call = (ins_dat_i[15:13] === 3'b010);
	wire is_load = (ins_dat_i[15] === 1'b1);
	wire is_ujump = (ins_dat_i[15:13] === 3'b000);
	wire is_zjump = (ins_dat_i[15:13] === 3'b001);
	wire [13:1] target = ins_dat_i[12:0];

	// The microprocessor needs to fetch instructions from
	// somewhere; the program counter (PC) register tells
	// where.
	reg [13:1] pc;
	assign ins_adr_o = pc;

	// Unlike the instruction bus, which operates permanently
	// in a read-only manner, the data bus may be used to
	// fetch or store to memory.  Thus, we need a signal to
	// indicate what operation is required of the memory
	// system.
	wire is_store = (is_alu & ins_dat_i[5]);
	reg dat_we;
	assign dat_we_o = dat_we;

	// The Wishbone bus requires that we qualify all bus
	// transactions with a CYC_O signal, indicating when
	// the master wants access to the bus.  In the unlikely
	// event that the J1A is used in a multiprocessor
	// scenario on a single bus, this signal is used to
	// arbitrate for bus access.
	reg ins_cyc;	assign ins_cyc_o = ins_cyc;
	
	wire is_fetch = ins_dat_i[11:8] === 4'b1100;
	wire is_data_access = (is_alu & (is_fetch | is_store));
	reg dat_cyc;
	assign dat_cyc_o = dat_cyc;

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
	assign shr_stb_o = (ins_cyc | dat_cyc);

	// When the processor executes a fetch or store instruction,
	// the address always appears at the top of the data stack.
	// So, we just export the top of stack directly to the
	// dat_adr_o bus as-is.
	//
	// Likewise, in the event that the CPU executes a store
	// operation, the second top of stack holds the datum to 
	// push into memory.  Thus, we just hard-wire the 2nd
	// top of stack to the data output pins.
	reg [15:0] t;
	reg [15:0] ds[31:0];
	reg [4:0] dsp;
	wire [15:0] s = ds[dsp];
	
	assign dat_adr_o[15:1] = t[15:1];
	assign dat_dat_o = s;

	// The R pseudo-register always refers to the current top
	// of the return stack.
	reg [15:0] rs[31:0];
	reg [4:0] rsp;
	wire [15:0] r = rs[rsp];

	// The processor works by asynchronously computing its next
	// state, then registering that state on the next rising
	// edge of the system clock.  We therefore need temporary
	// latches, registers, and/or wire-buses to assign this
	// next-state to.
	reg [13:1] pc_n;
	reg [15:0] t_n;
	reg [15:0] s_n;
	reg [15:0] r_n;
	reg [4:0] dsp_n;
	reg [4:0] rsp_n;
	reg dswe; 		// data stack write enable
	reg rswe; 		// return stack write enable

	// The asynchronous logic works to compute the processor's
	// next state.  (Part 2)
	wire tzero = (t === 16'h0000);

	always @* begin
		// If the instruction is an immediate load, we load
		// the value onto the data stack.
		if (is_load) begin
			pc_n <= pc+1;
			s_n <= t;
			t_n <= {1'b0, ins_dat_i[14:0]};
			r_n <= r;
			dsp_n <= dsp+1;
			rsp_n <= rsp;
			dswe <= 1;
			rswe <= 0;
		end

		// If we're executing an ALU instruction packet,
		// note that various bit-fields are used to concurrently
		// update different parts of the CPU and/or external
		// memory state.
		else if (is_alu) begin
			// Return from subroutine support
			pc_n <= (ins_dat_i[12])? r : pc+1;

			// Data Stack Manipulations
			case (ins_dat_i[11:8])
				4'h0: t_n <= t;
				4'h1: t_n <= s;
				4'h2: t_n <= t + s;
				4'h3: t_n <= t & s;
				4'h4: t_n <= t | s;
				4'h5: t_n <= t ^ s;
				4'h6: t_n <= ~t;
				4'h7: t_n <= {16{t === s}};
				4'h8: t_n <= {16{$signed(s) < $signed(t)}};
				4'h9: t_n <= s >> t[3:0];
				4'hA: t_n <= t-1;
				4'hB: t_n <= r;
				4'hC: t_n <= dat_dat_i;
				4'hD: t_n <= s << t[3:0];
				4'hE: t_n <= {3'b000, rsp, 3'b000, dsp};
				4'hF: t_n <= {16{$unsigned(s) < $unsigned(t)}};
			endcase

			// This instruction field supports DUP, OVER, et. al.
			s_n <= (ins_dat_i[7])? t : s;
			dswe <= ins_dat_i[7];

			// This instruction field supports >R, DO/LOOP, et. al.
			rswe <= ins_dat_i[6];
			r_n <= (is_alu & ins_dat_i[6])? t : r;
			
			// Instruction bit 5 is handled in the wire dat_we_o.
			
			// In the J1, J0, and J1A processors, bit 4 remains unused.
			// For compatibility with future processors, always leave
			// bit 4 clear.
			
			// Stack increment/decrement control
			rsp_n <= rsp + {{3{ins_dat_i[3]}}, ins_dat_i[3:2]};
			dsp_n <= dsp + {{3{ins_dat_i[1]}}, ins_dat_i[1:0]};
		end
		
		// Jump instructions.
		else if (is_ujump) begin
			pc_n <= target;
			t_n <= t;
			s_n <= s;
			dswe <= 0;
			rswe <= 0;
			r_n <= r;
			rsp_n <= rsp;
			dsp_n <= dsp-1;
		end

		else if (is_zjump) begin
			pc_n <= tzero? target : pc+1;
			t_n <= s;
			s_n <= s;
			dswe <= 0;
			rswe <= 0;
			r_n <= r;
			rsp_n <= rsp;
			dsp_n <= dsp-1;
		end
		
		else if (is_call) begin
			pc_n <= target;
			t_n <= t;
			s_n <= s;
			dswe <= 0;
			rswe <= 1;
			r_n <= pc+1;
			rsp_n <= rsp+1;
			dsp_n <= dsp;
		end
		
		else begin
			pc_n <= 13'hxxxx;
			t_n <= 16'hxxxx;
			s_n <= 16'hxxxx;
			dswe <= 1'bx;
			rswe <= 1'bx;
			r_n <= 16'hxxxx;
			rsp_n <= 5'hxx;
			dsp_n <= 5'hxx;
		end
	end

	always @(posedge sys_clk_i) begin
		if (sys_res_i) begin
			pc <= 15'h0000;
			ins_cyc <= 1;
			t <= 16'h0000;
			rsp <= 5'b00000;// rsp_n <= 5'b00000;
			dsp <= 5'b00000;// dsp_n <= 5'b00000;
			dat_cyc <= 0;
			dat_we <= 0;
		end else begin
			dat_cyc <= is_data_access;
			dat_we <= is_store;

			if (shr_stb_o & shr_ack_i) begin
				pc <= pc_n;
				t <= t_n;

				if(dswe) ds[dsp_n] <= s_n;
				dsp <= dsp_n;

				if(rswe) rs[rsp_n] <= r_n;
				rsp <= rsp_n;
			end
		end
	end
endmodule
