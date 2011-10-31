`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   15:12:04 10/30/2011
// Design Name:   M_uxa_ps2_fifo
// Module Name:   /Users/kc5tja/tmp/kestrel/2/nexys2/uxa/ps2io/T_uxa_ps2_fifo.v
// Project Name:  ps2io
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: M_uxa_ps2_fifo
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module T_uxa_ps2_fifo;

	// Inputs
	reg [7:0] d_i;
	reg we_i;
	reg wp_inc_i;
	reg rp_inc_i;
	reg sys_clk_i;
	reg sys_reset_i;

	// Outputs
	wire [7:0] q_o;
	wire full_o;
	wire data_available_o;

	// Instantiate the Unit Under Test (UUT)
	M_uxa_ps2_fifo uut (
		.d_i(d_i), 
		.we_i(we_i), 
		.wp_inc_i(wp_inc_i), 
		.q_o(q_o), 
		.rp_inc_i(rp_inc_i), 
		.full_o(full_o), 
		.data_available_o(data_available_o), 
		.sys_clk_i(sys_clk_i), 
		.sys_reset_i(sys_reset_i)
	);

	always begin
		#40 sys_clk_i <= ~sys_clk_i;
	end

	initial begin
		// Initialize Inputs
		d_i = 0;
		we_i = 0;
		wp_inc_i = 0;
		rp_inc_i = 0;
		sys_clk_i = 0;
		sys_reset_i = 0;

		// Asserting reset should bring our outputs to
		// well-known states.

		#80 sys_reset_i = 1;
		#80 sys_reset_i = 0;
		#80 if (full_o != 0) begin
			$display("Unexpectedly full queue");
		end
		if (data_available_o != 0) begin
			$display("Unexpected data in the queue");
		end

		// Writing a single byte to the queue should
		// result in q_o seeing the changes.  This is
		// because both read and write pointers should
		// match.
		#160 d_i <= 8'b10110111; we_i <= 1;
		#80 we_i <= 0;
		#80 if (full_o != 0) begin
			$display("A single byte shouldn't fill up a 16-deep queue.");
			$stop;
		end
		if (data_available_o != 0) begin
			$display("Write pointer hasn't been incremented yet, so data available flag should be false.");
			$stop;
		end
		if (q_o != 8'hB7) begin
			$display("Data stored doesn't match that which is retrievable.");
			$stop;
		end
		// Related to the above tests, bumping the write
		// pointer should result in data available indication.
		wp_inc_i <= 1;
		#80 wp_inc_i <= 0;
		#80 if (data_available_o != 1) begin
			$display("Write pointer bumped; data should now be available.");
			$stop;
		end
		// Related to the above tests again, bumping the read
		// pointer should result in an unknown q_o state, and
		// data_available_o going false (since we've read all
		// available known data).
		rp_inc_i <= 1;
		#80 rp_inc_i <= 0;
		#80 if (data_available_o != 0) begin
			$display("We read all available data; no more should exist.");
			$stop;
		end
		if (q_o != 8'bxxxxxxxx) begin
			$display("Bus should be in unknown state.");
			$stop;
		end
		
		// For our next test, let's attempt to push 20 values into
		// the queue.  We'll just push the values 1 through 20.
		// The queue should indicate that data is both available and
		// that the queue is full.
		#160 we_i <= 1; d_i <= 8'd1;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd2; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd3; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd4; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd5; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd6; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd7; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd8; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd9; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd10; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd11; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd12; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd13; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd14; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd15; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 // At this point, full_o should be asserted.  But,
		 // we're stress-testing the circuit, so we ignore it.
		 // Keep on pushing values.
		 #80 we_i <= 1; d_i <= 8'd16; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd17; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd18; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd19; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		 #80 we_i <= 1; d_i <= 8'd20; wp_inc_i <= 0;
		 #80 we_i <= 0; wp_inc_i <= 1;
		#80 wp_inc_i <= 0; if (full_o != 1) begin
			$display("Hungry hippo is hungry.  Queue should be packed.");
			$stop;
		end
		if (data_available_o != 1) begin
			$display("A full queue always has data available.");
		end
		// Now, if we read back these values, we should see
		// the sequence 1..15.
		if (q_o != 8'd1) begin
			$display("Data byte 1 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (full_o != 0) begin
			$display("We read one byte from the queue; we shouldn't be full anymore."); $stop;
		end

		if (q_o != 8'd2) begin
			$display("Data byte 2 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd3) begin
			$display("Data byte 3 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd4) begin
			$display("Data byte 4 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd5) begin
			$display("Data byte 5 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd6) begin
			$display("Data byte 6 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd7) begin
			$display("Data byte 7 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd8) begin
			$display("Data byte 8 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd9) begin
			$display("Data byte 9 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd10) begin
			$display("Data byte 10 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd11) begin
			$display("Data byte 11 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd12) begin
			$display("Data byte 12 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd13) begin
			$display("Data byte 13 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd14) begin
			$display("Data byte 14 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (q_o != 8'd15) begin
			$display("Data byte 15 invalid."); $stop;
		end
		rp_inc_i <= 1; #80 rp_inc_i <= 0; #80;

		if (data_available_o != 0) begin
			$display("We read all available bytes.  No more should be available."); $stop;
		end
		if (full_o != 0) begin
			$display("We read all bytes from the queue; we shouldn't be full anymore."); $stop;
		end
	end
      
endmodule

