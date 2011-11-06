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
// Tool versi		ons:  
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
	reg [15:0] dat_dat_i;

	// Outputs
	wire [13:1] ins_adr_o;
	wire ins_cyc_o;
	wire shr_stb_o;
	wire [15:1] dat_adr_o;
	wire [15:0] dat_dat_o;
	wire dat_cyc_o;
	wire dat_we_o;

	// Instantiate the Unit Under Test (UUT)
	M_j1a uut (
		.sys_res_i(sys_res_i), 
		.sys_clk_i(sys_clk_i), 
		.ins_adr_o(ins_adr_o), 
		.ins_dat_i(ins_dat_i), 
		.ins_cyc_o(ins_cyc_o), 
		.shr_stb_o(shr_stb_o), 
		.shr_ack_i(shr_ack_i),
		.dat_adr_o(dat_adr_o),
		.dat_dat_o(dat_dat_o),
		.dat_dat_i(dat_dat_i),
		.dat_cyc_o(dat_cyc_o),
		.dat_we_o(dat_we_o)
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

		if (ins_adr_o !== 13'h0000) begin
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
		if (ins_adr_o !== 13'h0000) begin
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
		ins_dat_i <= 16'h6000; // NOP instruction.
		wait(~sys_clk_i); wait(sys_clk_i); shr_ack_i <= 1;
		wait(~sys_clk_i); wait(sys_clk_i); shr_ack_i <= 0;
		wait(~sys_clk_i); wait(sys_clk_i);
		if (ins_adr_o !== 13'h0001) begin
			$display("J1A:0300 An acknowledged memory cycle lets the CPU continue."); $stop;
		end
		
		//
		// AS A    microprocessor maker
		// I WANT  the CPU to run full tilt if the bus can keep up
		// SO THAT I can pull maximum performance out if needed.
		//
		shr_ack_i <= 1;
		wait(~sys_clk_i); wait(sys_clk_i); wait(~sys_clk_i);
		if (ins_adr_o !== 13'h0002) begin
			$display("J1A:0400 Pegging ACK should get CPU to run full speed"); $stop;
		end
		wait(sys_clk_i); wait(~sys_clk_i);
		if (ins_adr_o !== 13'h0003) begin
			$display("J1A:0500 Pegging ACK should get CPU to run full speed"); $stop;
		end
		shr_ack_i <= 0;
		wait(sys_clk_i);
		
		//
		// AS A    programmer
		// I WANT  the CPU to accept numeric constants
		// SO THAT I can push addresses and parameters on the stack.
		//
		ins_dat_i <= 16'h9234;
		shr_ack_i <= 1;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hA468;
		wait(~sys_clk_i); wait(sys_clk_i);
		#25;
		shr_ack_i <= 0;
		if (dat_adr_o !== 15'b001001000110100) begin
			$display("J1A:0600 Literal push instruction should have executed"); $stop;
		end
		if (dat_dat_o !== 16'b0001001000110100) begin
			$display("J1A:0601 Literal push instruction should have executed"); $stop;
		end
		wait(sys_clk_i);
		
		//
		// AS A    CPU designer
		// I WANT  the CPU to not update its state when ACK_I is low
		// SO THAT spurious bus states don't cause invalid instructions to execute.
		//
		ins_dat_i <= 16'h9999;
		shr_ack_i <= 0;
		wait(~sys_clk_i); wait(sys_clk_i);
		#25;
		if(dat_adr_o == 15'b000110011001100) begin
			$display("J1A:0610 Literal push w/out ACK should never have happened"); $stop;
		end
		
		//
		// AS A    CPU designer
		// I WANT  the CPU to execute a host of arithmetic and/or logic instructions
		// SO THAT the J1 can be applied to useful tasks.
		//
		shr_ack_i <= 1;

		// T <= T
		ins_dat_i <= 16'h8210;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6000;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0011_0011_000) begin
			$display("J1A:0700 T<-T instruction"); $stop;
		end

		// T <= S
		ins_dat_i <= 16'h8210;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6100;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0010_0001_000) begin
			$display("J1A:0710 T<-S instruction"); $stop;
		end

		// T <= T+S
		ins_dat_i <= 16'h8210;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6200;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0101_0100_000) begin
			$display("J1A:0720 T<-T+S instruction"); $stop;
		end

		// T <= T /\ S
		ins_dat_i <= 16'h8A50;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6300;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0010_0001_000) begin
			$display("J1A:0730 T<-T&S instruction"); $stop;
		end

		// T <= T \/ S
		ins_dat_i <= 16'h8A50;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8338;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6400;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_1011_0111_100) begin
			$display("J1A:0740 T<-T|S instruction"); $stop;
		end

		// T <= T (+) S
		ins_dat_i <= 16'h8210;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6500;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0001_0010_000) begin
			$display("J1A:0750 T<-T^S instruction"); $stop;
		end

		// T <= ~T
		ins_dat_i <= 16'h8210;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6600;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b1111_1100_1100_111) begin
			$display("J1A:0760 T<-~T instruction"); $stop;
		end

		// T <= T==S (false)
		ins_dat_i <= 16'h8210;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6700;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0000_0000_000) begin
			$display("J1A:0770 T<-T==S instruction"); $stop;
		end

		// T <= T==S (true)
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6700;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b1111_1111_1111_111) begin
			$display("J1A:0771 T<-T==S instruction"); $stop;
		end

		// T <= T<S (signed; false)
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8210;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6800;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0000_0000_000) begin
			$display("J1A:0780 T<-S<T (signed) instruction"); $stop;
		end

		// T <= T<S (signed; true)
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6600;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8210;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6800;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b1111_1111_1111_111) begin
			$display("J1A:0781 T<-S<T (signed) instruction"); $stop;
		end

		// T <= S >> T
		ins_dat_i <= 16'hF330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8008;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6900;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0000_0111_001) begin
			$display("J1A:0790 T<-S>>T (signed) instruction"); $stop;
		end

		// T <= T-1
		ins_dat_i <= 16'h8330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6A00;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0011_0010_111) begin
			$display("J1A:07A0 T<-T-1 instruction"); $stop;
		end
		
		// To test the R-stack, we need to invoke some logic which
		// we haven't written explicit tests for yet.  Specifically,
		// we're going to load a constant, then transfer it to the
		// R stack WITHOUT adjusting the return stack pointer.
		// Then we load another constant, and invoke the R@ primitive.
		// Our constant should be what we "pushed" before.
		//
		// T <= R
		ins_dat_i <= 16'h9234;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6040;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hFFFF;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'h3FFF) begin
			$display("J1A:07B0 T<-R setup failure"); $stop;
		end
		ins_dat_i <= 16'h6B00;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0001_0010_0011_010) begin
			$display("J1A:07B1 T<-R instruction"); $stop;
		end
		
		// This next batch of tests exercises the CPU's ability to
		// *read* from its data bus.  We need to cover single-cycle
		// and multi-cycle reads to ensure proper operation.  Since
		// DAT_CYC_O asserts during the read instruction asynchron-
		// ously, we expect the data read cycle will complete synch-
		// ronously with the read instruction itself.
		ins_dat_i <= 16'h9234;
		dat_dat_i <= 16'hBEEF;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0001_0010_0011_010) begin
			$display("J1A:07C0 T<-MEM[T] instruction setup failure"); $stop;
		end
		if(dat_cyc_o !== 0) begin
			$display("J1A:07C1 Not expecting data read to happen yet"); $stop;
		end
		if(dat_we_o !== 0) begin
			$display("J1A:07C2 Expecting the bus to be in read mode"); $stop;
		end
		
		ins_dat_i <= 16'h6C00; #25;
		if(dat_cyc_o !== 1) begin
			$display("J1A:07C3 Expecting data read to happen now"); $stop;
		end
		if(dat_we_o !== 0) begin
			$display("J1A:07C4 Expecting the bus to be in read mode"); $stop;
		end
		if(dat_adr_o !== 15'b0001_0010_0011_010) begin
			$display("J1A:07C5 T<-MEM[T] instruction setup failure"); $stop;
		end
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hE666; #25;
		if(dat_cyc_o !== 0) begin
			$display("J1A:07C6 Expecting data read to finish in a single cycle"); $stop;
		end
		if(dat_we_o !== 0) begin
			$display("J1A:07C7 Expecting the bus to be in read mode"); $stop;
		end
		if(dat_adr_o !== 15'b1011_1110_1110_111) begin
			$display("J1A:07C8 T<-MEM[T] instruction failure"); $stop;
		end
		
		// -- multicycle with wait states --
		
		ins_dat_i <= 16'he428;
		dat_dat_i <= 16'hCC88;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_cyc_o !== 0) begin
			$display("J1A:07C9 Not expecting data read to happen yet"); $stop;
		end
		if(dat_we_o !== 0) begin
			$display("J1A:07CA Expecting the bus to be in read mode"); $stop;
		end
		
		ins_dat_i <= 16'h6C00; shr_ack_i <= 0; #25;
		if(dat_cyc_o !== 1) begin
			$display("J1A:07CB Expecting data read to happen now"); $stop;
		end
		if(dat_we_o !== 0) begin
			$display("J1A:07CC Expecting the bus to be in read mode"); $stop;
		end

		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_cyc_o !== 1) begin
			$display("J1A:07CD Bus should still be in read state"); $stop;
		end
		if(dat_we_o !== 0) begin
			$display("J1A:07CE Expecting the bus to be in read mode"); $stop;
		end
		if(dat_adr_o !== 15'b0110_0100_0010_100) begin
			$display("J1A:07CF T<-MEM[T] instruction failure"); $stop;
		end
		
		wait(~sys_clk_i); wait(sys_clk_i);
		if(dat_cyc_o !== 1) begin
			$display("J1A:07C10 Bus should still be in read state"); $stop;
		end
		if(dat_we_o !== 0) begin
			$display("J1A:07C11 Expecting the bus to be in read mode"); $stop;
		end
		if(dat_adr_o !== 15'b0110_0100_0010_100) begin
			$display("J1A:07C12 T<-MEM[T] instruction failure"); $stop;
		end
		
		shr_ack_i <= 1;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hE666;  #25;
		if(dat_cyc_o !== 0) begin
			$display("J1A:07C13 Bus read should have finished"); $stop;
		end
		if(dat_we_o !== 0) begin
			$display("J1A:07C14 Expecting the bus to be in read mode"); $stop;
		end
		if(dat_adr_o !== 15'b1100_1100_1000_100) begin
			$display("J1A:07C15 T<-MEM[T] instruction failure"); $stop;
		end

		// T <= S << T
		ins_dat_i <= 16'hF330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8004;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6D00;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0011_0011_0000_000) begin
			$display("J1A:07D0 T<-S>>T (signed) instruction"); $stop;
		end
		
		// We elect to skip the DEPTH command, since frankly,
		// I don't know what depth we _should_ be at now.
		// No instruction exists to reset the data or return
		// stack pointers, so we're going to have to take it on
		// faith that the depth instruction works as expected.
		
		// T <= S < T (unsigned) (false)
		ins_dat_i <= 16'hF330;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8004;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6F00;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0000_0000_0000_000) begin
			$display("J1A:07F0 T<-S<T (unsigned) instruction"); $stop;
		end
		
		// T <= S < T (unsigned) (true)
		ins_dat_i <= 16'h8004;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8004;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6600;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6F00;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b1111_1111_1111_111) begin
			$display("J1A:07F1 T<-S<T (unsigned) instruction"); $stop;
		end
		
		// Now that we're done testing the ALU operation selection
		// field, let's now work on the T->N bit.
		ins_dat_i <= 16'hC444;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6080;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0100_0100_0100_010) begin
			$display("J1A:0800 T->N field setup fail"); $stop;
		end
		if(dat_dat_o !== 16'b0100_0100_0100_0100) begin
			$display("J1A:0801 T->N field fail"); $stop;
		end
		
		// Now, for something completely different -- SWAP.
		ins_dat_i <= 16'he666;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hC444;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hA222;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0010_0010_0010_001) begin
			$display("J1A:0900 SWAP setup fail"); $stop;
		end
		if(dat_dat_o !== 16'b0100_0100_0100_0100) begin
			$display("J1A:0910 SWAP setup fail"); $stop;
		end
		ins_dat_i <= 16'h6180;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_dat_o !== 16'b0010_0010_0010_0010) begin
			$display("J1A:0920 SWAP fail"); $stop;
		end
		if(dat_adr_o !== 15'b0100_0100_0100_010) begin
			$display("J1A:0930 SWAP fail"); $stop;
		end
		ins_dat_i <= 16'h6103;
		wait(~sys_clk_i); wait(sys_clk_i);
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0110_0110_0110_011) begin
			$display("J1A:0930 SWAP fail"); $stop;
		end
		
		// OVER
		ins_dat_i <= 16'he666;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hC444;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hA222;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_dat_o !== 16'b0100_0100_0100_0100) begin
			$display("J1A:0A10 OVER setup fail"); $stop;
		end
		if(dat_adr_o !== 15'b0010_0010_0010_001) begin
			$display("J1A:0A00 OVER setup fail"); $stop;
		end
		ins_dat_i <= 16'h6181;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_dat_o !== 16'b0010_0010_0010_0010) begin
			$display("J1A:0A20 OVER fail"); $stop;
		end
		if(dat_adr_o !== 15'b0100_0100_0100_010) begin
			$display("J1A:0930 OVER fail"); $stop;
		end
		ins_dat_i <= 16'h6103;
		wait(~sys_clk_i); wait(sys_clk_i);
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0100_0100_0100_010) begin
			$display("J1A:0A30 OVER fail"); $stop;
		end
		
		// >R, R@, and R>
		ins_dat_i <= 16'hF777;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hE666;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hC444;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'hA222;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h6147; // >R, I hope
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0100_0100_0100_010) begin
			$display("J1A:0B00 >R fail"); $stop;
		end
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0110_0110_0110_011) begin
			$display("J1A:0B00 >R fail"); $stop;
		end
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0111_0111_0111_011) begin
			$display("J1A:0B00 >R fail"); $stop;
		end
		ins_dat_i <= 16'h6B81; // R@, I hope
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0110_0110_0110_011) begin
			$display("J1A:0B00 >R fail"); $stop;
		end
		ins_dat_i <= 16'h6B8D; // R>, I hope
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0110_0110_0110_011) begin
			$display("J1A:0B00 >R fail"); $stop;
		end
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0100_0100_0100_010) begin
			$display("J1A:0B00 >R fail"); $stop;
		end
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b0010_0010_0010_001) begin
			$display("J1A:0B00 >R fail"); $stop;
		end
		
		//
		// AS A    Programmer
		// I WANT  a processor with control flow primitives
		// SO THAT programs can respond to stimuli at run-time
		//
		// --- unconditional branch
		ins_dat_i <= 16'h1ABC;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(ins_adr_o !== 13'b1_1010_1011_1100) begin
			$display("J1A:0C00 Jump to location $3578 failed"); $stop;
		end
		
		// --- conditional branch (true)
		ins_dat_i <= 16'hD555;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8000;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h2040;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(ins_adr_o !== 13'b0_0000_0100_0000) begin
			$display("J1A:0D00 Z-Jump to location $0080 failed"); $stop;
		end
		if(dat_adr_o !== 15'b0101_0101_0101_010) begin
			$display("J1A:0D01 Z-jump pop failure"); $stop;
		end
		
		// --- conditional branch (false)
		ins_dat_i <= 16'hD555;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h8001;
		wait(~sys_clk_i); wait(sys_clk_i);
		ins_dat_i <= 16'h2048;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(ins_adr_o !== 13'b0_0000_0100_0011) begin
			$display("J1A:0D10 Z-Jump to location $0090 failed"); $stop;
		end
		if(dat_adr_o !== 15'b0101_0101_0101_010) begin
			$display("J1A:0D11 Z-jump pop failure"); $stop;
		end
		
		// --- subroutine call
		ins_dat_i <= 16'h4040;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(ins_adr_o !== 13'b0_0000_0100_0000) begin
			$display("J1A:0D20 CALL to location $0080 failed"); $stop;
		end
		ins_dat_i <= 16'h6B01;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(dat_adr_o !== 15'b000_0000_0010_0010) begin
			// Recall the test above ended at address $0086 (byte).
			$display("J1A:0D21 CALL failed to push return address"); $stop;
		end
		
		// --- return
		ins_dat_i <= 16'h700C;
		wait(~sys_clk_i); wait(sys_clk_i); #25;
		if(ins_adr_o !== 13'b0_0000_0100_0100) begin
			$display("J1A:0D30 Return failed"); $stop;
		end
	end
endmodule

