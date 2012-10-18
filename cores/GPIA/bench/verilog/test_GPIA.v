`timescale 1ns / 1ps

module test_GPIA();
	reg	[15:0]	story_o;

	reg				clk_o;
	reg				rst_o;

	reg				adr_o;
	reg				we_o;
	reg				cyc_o;
	reg				stb_o;
	reg	[15:0]	dat_o;

	reg	[15:0]	port_o;
	wire	[15:0]	port_i;
	wire	[15:0]	dat_i;
	wire				ack_i;

	GPIA gpia(
		.RST_I(rst_o),
		.CLK_I(clk_o),
		.PORT_O(port_i),
		.PORT_I(port_o),
		
		.ADR_I(adr_o),
		.WE_I(we_o),
		.CYC_I(cyc_o),
		.STB_I(stb_o),
		.DAT_I(dat_o),
		.DAT_O(dat_i),
		.ACK_O(ack_i)
	);

	always begin
		#50 clk_o <= ~clk_o;
	end

	initial begin
		clk_o <= 0;
		rst_o <= 0;
		adr_o <= 0;
		we_o <= 0;
		cyc_o <= 0;
		stb_o <= 0;
		dat_o <= 16'h0000;
		wait(clk_o); wait(~clk_o);

		// AS A systems engineer
		// I WANT all outputs to go to zero upon reset
		// SO THAT the system starts in a well-known state.
		
		story_o <= 16'h0000;
		rst_o <= 1;
		wait(clk_o); wait(~clk_o);
		rst_o <= 0;
		wait(clk_o); wait(~clk_o);
		wait(clk_o); wait(~clk_o);
		if(port_i !== 16'h0000) begin
			$display("Reset should set output port to all zeros."); $stop;
		end
		
		// AS A software engineer
		// I WANT to be able to write a value to the output port
		// SO THAT peripherals may be controlled.
		
		story_o <= 16'h0010;
		adr_o <= 1;
		we_o <= 1;
		cyc_o <= 1;
		stb_o <= 1;
		dat_o <= 16'hDEAD;
		wait(clk_o); wait(~clk_o);
		if(port_i !== 16'hDEAD) begin
			$display("Writing to a port should take effect immediately."); $stop;
		end
		wait(clk_o); wait(~clk_o);

		// AS A hardware engineer
		// I WANT the GPIA to issue its own acknowledge signal for a write cycle
		// SO THAT the bus master doesn't hang indefinitely.

		story_o <= 16'h0020;
		adr_o <= 1;
		we_o <= 1;
		cyc_o <= 1;
		stb_o <= 1;
		dat_o <= 16'hBEEF;
		wait(clk_o); wait(~clk_o);
		if(~ack_i) begin
			$display("ACK signal expected to complete bus transaction."); $stop;
		end
		wait(clk_o); wait(~clk_o);

		// AS A hardware engineer
		// I WANT the GPIA to handle back-to-back writes gracefully
		// SO THAT the bus master doesn't get confused about its bus timing.

		story_o <= 16'h0025;
		adr_o <= 1;
		we_o <= 1;
		cyc_o <= 1;
		stb_o <= 1;
		dat_o <= 16'hBEEF;
		wait(clk_o); wait(~clk_o);
		wait(clk_o); wait(~clk_o);
		if(ack_i) begin
			$display("ACK signal expected to be negated at this point."); $stop;
		end
		wait(clk_o); wait(~clk_o);
		if(~ack_i) begin
			$display("ACK for 2nd cycle supposed to be here."); $stop;
		end
		wait(clk_o); wait(~clk_o);

		// AS A software engineer
		// I WANT to read the last written contents of the output port
		// SO THAT I can bit-bang with impunity.
		
		story_o <= 16'h0030;
		adr_o <= 1;
		we_o <= 1;
		cyc_o <= 1;
		stb_o <= 1;
		dat_o <= 16'hFEED;
		wait(clk_o); wait(~clk_o);
		wait(clk_o); wait(~clk_o);

		adr_o <= 1;
		we_o <= 0;
		cyc_o <= 1;
		stb_o <= 1;
		wait(clk_o); wait(~clk_o);
		if(dat_i !== 16'hFEED) begin
			$display("We just wrote a value; we should be able to read it again."); $stop;
		end
		wait(clk_o); wait(~clk_o);

		// AS A software engineer
		// I WANT to read the status of the input ports
		// SO THAT I can respond to external stimuli.
		
		story_o <= 16'h0040;
		adr_o <= 0;
		we_o <= 0;
		cyc_o <= 1;
		stb_o <= 1;
		port_o <= 16'hFACE;
		wait(clk_o); wait(~clk_o);
		if(dat_i !== 16'hFACE) begin
			$display("Expected to read input port value"); $stop;
		end
		wait(clk_o); wait(~clk_o);

		// AS A hardware engineer
		// I WANT the ACK_O signal to become valid when the data bus is driven.
		// SO THAT the bus master doesn't hang indefinitely waiting for data, or latching bad data.
		
		story_o <= 16'h0050;
		adr_o <= 0;
		we_o <= 0;
		cyc_o <= 1;
		stb_o <= 1;
		port_o <= 16'h0BAD;
		wait(clk_o); wait(~clk_o);
		if(~ack_i) begin
			$display("Expected to ACK at the same time as the driven data"); $stop;
		end
		wait(clk_o); wait(~clk_o);

		// AS A hardware engineer
		// I WANT the GPIA to negate its ACK once no longer addressed
		// SO THAT other bus masters can start using the bus right away.
		
		story_o <= 16'h0060;
		adr_o <= 0;
		we_o <= 0;
		cyc_o <= 1;
		stb_o <= 1;
		port_o <= 16'hC0FF;
		wait(clk_o);
		cyc_o <= 0;
		wait(~clk_o);
		if(~ack_i) begin
			$display("Synchronous bus: Should not negate right now."); $stop;
		end
		wait(clk_o); wait(~clk_o);
		if(ack_i) begin
			$display("Expected ACK to negate now."); $stop;
		end
		
		story_o <= 16'h0070;
		adr_o <= 0;
		we_o <= 0;
		cyc_o <= 1;
		stb_o <= 1;
		port_o <= 16'h600D;
		wait(clk_o);
		stb_o <= 0;
		wait(~clk_o);
		if(~ack_i) begin
			$display("Synchronous bus: Should not negate right now."); $stop;
		end
		wait(clk_o); wait(~clk_o);
		if(ack_i) begin
			$display("Expected ACK to negate now."); $stop;
		end
		
		// AS A hardware engineer
		// I WANT the GPIA to properly differentiate back to back reads
		// SO THAT the bus master timing remains intact.
		
		story_o <= 16'h0080;
		adr_o <= 0;
		we_o <= 0;
		cyc_o <= 1;
		stb_o <= 1;
		port_o <= 16'h7EA0;
		wait(clk_o); wait(~clk_o);
		wait(clk_o); wait(~clk_o);
		if(ack_i) begin
			$display("Expected new bus cycle this cycle"); $stop;
		end
		wait(clk_o); wait(~clk_o);
		if(~ack_i) begin
			$display("Expected ACK for 2nd cycle here."); $stop;
		end
		
		// We're done.

		story_o <= 16'hFFFF;
		wait(clk_o); wait(~clk_o);
		$stop;
	end
endmodule
