`timescale 1ns/1ps

module TEST_VRAM16K();
	reg [15:0] story;

	// SYSCON
	
	reg clk_i;
	
	// MASTER A
	
	wire				a_ack_i;
	reg	[13:1]	a_adr_o;
	reg				a_cyc_o;
	wire	[15:0]	a_dat_i;
	reg	[15:0]	a_dat_o;
	reg	[1:0]		a_sel_o;
	reg				a_stb_o;
	reg				a_we_o;

	// MASTER B
	
	wire				b_ack_i;
	reg	[13:1]	b_adr_o;
	reg				b_cyc_o;
	wire	[15:0]	b_dat_i;
	reg	[15:0]	b_dat_o;
	reg	[1:0]		b_sel_o;
	reg				b_stb_o;
	reg				b_we_o;

	VRAM16K vram(
		.CLK_I(clk_i),
		
		.A_ACK_O(a_ack_i),
		.A_ADR_I(a_adr_o),
		.A_CYC_I(a_cyc_o),
		.A_DAT_O(a_dat_i),
		.A_DAT_I(a_dat_o),
		.A_SEL_I(a_sel_o),
		.A_STB_I(a_stb_o),
		.A_WE_I(a_we_o),

		.B_ACK_O(b_ack_i),
		.B_ADR_I(b_adr_o),
		.B_CYC_I(b_cyc_o),
		.B_DAT_O(b_dat_i),
		.B_DAT_I(b_dat_o),
		.B_SEL_I(b_sel_o),
		.B_STB_I(b_stb_o),
		.B_WE_I(b_we_o)
	);

	always begin
		#10 clk_i <= ~clk_i;
	end

	initial begin
		clk_i <= 1;
		a_stb_o <= 0;  b_stb_o <= 0;
		a_cyc_o <= 0;  b_cyc_o <= 0;
		
		// AS A hardware engineer
		// I WANT the 16K RAM module to generate its own ACK signal for bus A
		// SO THAT I don't have to create one outside of the relevant circuitry.
		//
		// It needs to exhibit a single cycle of latency per bus transaction.
		// This is because at time T0, the master presents the address, but
		// the RAM hasn't seen the address yet.  At the next clock edge, the
		// RAM samples the address, which allows it to drive the data bus.
		// During this time (T1), the ACK signal should assert.  This will
		// allow the master to sample the data at clock edge T2.

		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		story <= 16'h0000;
		a_adr_o <= 13'h0000;
		a_cyc_o <= 1;
		a_sel_o <= 2'b11;
		a_stb_o <= 1;
		a_we_o <= 0;
		
		b_adr_o <= 16'h0000;
		b_cyc_o <= 0;
		b_sel_o <= 2'b00;
		b_stb_o <= 0;
		b_we_o <= 0;
		
		wait(clk_i); wait(~clk_i);

		if(~a_ack_i) begin
			$display("Expecting an ACK now.  RAM just now got the address, and has updated its data pins."); $stop;
		end

		if(b_ack_i) begin
			$display("What is B bus doing?"); $stop;
		end

		wait(clk_i); wait(~clk_i);

		if(a_ack_i) begin
			$display("Previous cycle terminated by ACK; new address not latched yet."); $stop;
		end

		if(b_ack_i) begin
			$display("What is B bus doing?!"); $stop;
		end

		wait(clk_i); wait(~clk_i);

		if(~a_ack_i) begin
			$display("Expecting an ACK now.  RAM just now got the address, and has updated its data pins."); $stop;
		end

		if(b_ack_i) begin
			$display("What is B bus doing?"); $stop;
		end

		// AS A hardware engineer
		// I WANT the 16K RAM module to generate its own ACK signal for bus B
		// SO THAT I don't have to create one outside of the relevant circuitry.

		wait(clk_i); wait(~clk_i);
		story <= 16'h0001;
		b_adr_o <= 13'h00FF;
		b_cyc_o <= 1;
		b_sel_o <= 2'b11;
		b_stb_o <= 1;
		b_we_o <= 0;
		
		a_adr_o <= 13'h0000;
		a_cyc_o <= 0;
		a_sel_o <= 2'b00;
		a_stb_o <= 0;
		a_we_o <= 0;
		
		wait(clk_i); wait(~clk_i);

		if(~b_ack_i) begin
			$display("Expecting an ACK now.  RAM just now got the address, and is presenting data."); $stop;
		end

		if(a_ack_i) begin
			$display("What is A bus doing?"); $stop;
		end

		wait(clk_i); wait(~clk_i);

		if(b_ack_i) begin
			$display("Wait-state.  We don't pipeline."); $stop;
		end

		if(a_ack_i) begin
			$display("What is A bus doing?!"); $stop;
		end
		
		wait(clk_i); wait(~clk_i);

		if(~b_ack_i) begin
			$display("Expecting an ACK now.  RAM just now got the address, and is presenting data."); $stop;
		end

		if(a_ack_i) begin
			$display("What is A bus doing?"); $stop;
		end

		b_cyc_o <= 0;
		b_stb_o <= 0;
		
		// AS A software engineer
		// I WANT the Kestrel-2 to have 16KB of video RAM
		// SO THAT I can render a complete 640x200 bitmapped display.
		
		story <= 16'h0003;
		a_adr_o <= 13'h0000;
		a_cyc_o <= 1;
		a_stb_o <= 1;
		a_we_o <= 1;
		a_sel_o <= 2'b11;
		a_dat_o <= 16'hFFFF;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		a_adr_o <= 13'h0002;
		a_dat_o <= 16'hAAAA;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		a_adr_o <= 13'h0800;
		a_dat_o <= 16'hFFFF;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		a_adr_o <= 13'h0802;
		a_dat_o <= 16'hAAAA;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		a_adr_o <= 13'h1000;
		a_dat_o <= 16'hFFFF;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		a_adr_o <= 13'h1002;
		a_dat_o <= 16'hAAAA;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		a_adr_o <= 13'h1800;
		a_dat_o <= 16'hFFFF;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		a_adr_o <= 13'h1802;
		a_dat_o <= 16'hAAAA;
		wait(clk_i); wait(~clk_i);
		wait(clk_i); wait(~clk_i);
		a_stb_o <= 0;
		b_adr_o <= 13'h0000;
		b_cyc_o <= 1;
		b_stb_o <= 1;
		b_we_o <= 0;
		b_sel_o <= 2'b11;
		wait(clk_i); wait(~clk_i);
		if(b_dat_i != 16'hFFFF) begin
			$display("Expected pixels to display at $0000"); $stop;
		end
		wait(clk_i); wait(~clk_i);
		b_adr_o <= 13'h0002;
		wait(clk_i); wait(~clk_i);
		if(b_dat_i != 16'hAAAA) begin
			$display("Expected pixels to display at $0000"); $stop;
		end
		wait(clk_i); wait(~clk_i);
		b_adr_o <= 13'h0800;
		wait(clk_i); wait(~clk_i);
		if(b_dat_i != 16'hFFFF) begin
			$display("Expected pixels to display at $0000"); $stop;
		end
		wait(clk_i); wait(~clk_i);
		b_adr_o <= 13'h0802;
		wait(clk_i); wait(~clk_i);
		if(b_dat_i != 16'hAAAA) begin
			$display("Expected pixels to display at $0000"); $stop;
		end
		wait(clk_i); wait(~clk_i);
		b_adr_o <= 13'h1000;
		wait(clk_i); wait(~clk_i);
		if(b_dat_i != 16'hFFFF) begin
			$display("Expected pixels to display at $0000"); $stop;
		end
		wait(clk_i); wait(~clk_i);
		b_adr_o <= 13'h1002;
		wait(clk_i); wait(~clk_i);
		if(b_dat_i != 16'hAAAA) begin
			$display("Expected pixels to display at $0000"); $stop;
		end
		wait(clk_i); wait(~clk_i);
		b_adr_o <= 13'h1800;
		wait(clk_i); wait(~clk_i);
		if(b_dat_i != 16'hFFFF) begin
			$display("Expected pixels to display at $0000"); $stop;
		end
		wait(clk_i); wait(~clk_i);
		b_adr_o <= 13'h1802;
		wait(clk_i); wait(~clk_i);
		if(b_dat_i != 16'hAAAA) begin
			$display("Expected pixels to display at $0000"); $stop;
		end
		wait(clk_i); wait(~clk_i);

		// AS A test engineer
		// I WANT this test to identify when it's done
		// SO THAT I don't stay up until 3AM trying to figure out why nothing's wrong with this module.
		
		story <= 16'hFFFF;
		$stop;
	end
endmodule
