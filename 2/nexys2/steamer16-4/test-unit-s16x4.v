`timescale 1ns / 1ps

`define RESET_ORIGIN 	16'hFFF0

module TEST_UNIT_S16X4();
	reg [15:0] story_o;

	reg clk_o;
	reg res_o;
	reg ack_o;
	reg [15:0] dat_o;

	wire [15:1] adr_i;
	wire we_i;
	wire cyc_i;
	wire [1:0] stb_i;
	wire vda_i;
	wire vpa_i;

	STEAMER16X4 cpu(
		.res_i(res_o),
		.clk_i(clk_o),

		.adr_o(adr_i),
		.we_o(we_i),
		.cyc_o(cyc_i),
		.stb_o(stb_i),
		.vpa_o(vpa_i),
		.vda_o(vda_i),
		
		.ack_i(ack_o),
		.dat_i(dat_o)
	);
 
	always begin
		#50 clk_o <= ~clk_o;
	end

	initial begin
		clk_o <= 0;
		res_o <= 0;
		ack_o <= 0;
		dat_o <= 16'hDEAD;

		wait(clk_o); wait(~clk_o);
		
		// AS A hardware engineer
		// I WANT the CPU to start execution at address $..FFF0
		// SO THAT I can jump to the appropriate initialization code.
		
		story_o <= 16'h0000;
		res_o <= 1;
		ack_o <= 1;
		wait(clk_o); wait(~clk_o);
		if(adr_i != (`RESET_ORIGIN >> 1)) begin
			$display("CPU should fetch its first instruction at $..FF0"); $stop;
		end
		if(we_i != 0) begin
			$display("CPU should not be writing after a reset."); $stop;
		end
		if(cyc_i != 1) begin
			$display("CPU should be in a bus cycle while fetching its first instructions."); $stop;
		end
		if(stb_i != 2'h3) begin
			$display("CPU should be fetching a full word."); $stop;
		end
		if(vpa_i != 1) begin
			$display("CPU should be trying to fetch from program space right now."); $stop;
		end
		if(vda_i != 0) begin
			$display("CPU should not be fetching an operand to an instruction."); $stop;
		end

		// AS A hardware engineer
		// I WANT the CPU to pause on a fetch when ACK_I is negated
		// SO THAT I can handle synchronous memories or slow peripherals.
		
		story_o <= 16'h0010;
		res_o <= 1;
		ack_o <= 0;
		wait(clk_o); wait(~clk_o);
		if(adr_i != (`RESET_ORIGIN >> 1)) begin
			$display("CPU should be fetching first instruction here."); $stop;
		end
		res_o <= 0;
		wait(clk_o); wait(~clk_o);
		if(adr_i != (`RESET_ORIGIN >> 1)) begin
			$display("CPU should still be fetching first instruction here."); $stop;
		end
		ack_o <= 1;
		dat_o <= 16'h1000;
		wait(clk_o); wait(~clk_o);
		if(adr_i != (`RESET_ORIGIN>>1)+1) begin
			$display("CPU should have advanced to the first operand here."); $stop;
		end

		// AS A software engineer
		// I WANT the CPU to fetch a literal value in response to the LIT opcode
		// SO THAT I can perform fetches and stores to program variables.
		
		story_o <= 16'h0020;
		res_o <= 1;
		ack_o <= 1;
		wait(clk_o); wait(~clk_o);
		if(vpa_i != 1) begin
			$display("CPU should be trying to fetch from program space right now."); $stop;
		end
		if(vda_i != 0) begin
			$display("CPU should not be fetching an operand to an instruction."); $stop;
		end
		res_o <= 0;
		dat_o <= 16'h1000;
		wait(clk_o); wait(~clk_o);
		if(vpa_i != 1) begin
			$display("CPU should still be trying to fetch from program space."); $stop;
		end
		if(vda_i != 1) begin
			$display("CPU should now be fetching an operand."); $stop;
		end
		dat_o <= 16'h1234;
		wait(clk_o); wait(~clk_o);
		if(adr_i != (`RESET_ORIGIN >> 1)+2) begin
			$display("CPU should have fetched opcode and operand by now."); $stop;
		end
		if(vda_i != 0) begin
			$display("It's exhausted its instruction stream.  It should be getting another instruction."); $stop;
		end

		// AS A software engineer
		// I WANT predictable NOP timing
		// SO THAT I can have cycle-accurate control over timing loops.
		
		story_o <= 16'h0030;
		res_o <= 1;
		ack_o <= 1;
		wait(clk_o); wait(~clk_o);
		if(vpa_i != 1) begin
			$display("CPU should be trying to fetch from program space right now."); $stop;
		end
		if(vda_i != 0) begin
			$display("CPU should not be fetching an operand to an instruction."); $stop;
		end
		res_o <= 0;
		dat_o <= 16'h0010;
		wait(clk_o); wait(~clk_o);
		if(cyc_i) begin
			$display("CPU should never engage the bus during a NOP."); $stop;
		end
		if(vda_i) begin
			$display("CPU should not be accessing data space here."); $stop;
		end
		if(vpa_i) begin
			$display("CPU should not be accessing program space here."); $stop;
		end
		wait(clk_o); wait(~clk_o);
		if(cyc_i) begin
			$display("CPU should never engage the bus during a NOP."); $stop;
		end
		if(vda_i) begin
			$display("CPU should not be accessing data space here."); $stop;
		end
		if(vpa_i) begin
			$display("CPU should not be accessing program space here."); $stop;
		end
		wait(clk_o); wait(~clk_o);
		if(~cyc_i) begin
			$display("CPU should try fetching an operand here."); $stop;
		end
		if(~vda_i) begin
			$display("CPU should be accessing an operand here."); $stop;
		end
		if(~vpa_i) begin
			$display("CPU should be accessing program space here."); $stop;
		end
		if(stb_i != 2'b11) begin
			$display("Fetching a full word here."); $stop;
		end
		if(adr_i != (`RESET_ORIGIN>>1)+1) begin
			$display("Fetching operand from wrong address"); $stop;
		end
		wait(clk_o); wait(~clk_o);
		if(~cyc_i) begin
			$display("CPU should try fetching an opcode here."); $stop;
		end
		if(vda_i) begin
			$display("CPU should be accessing an opcode here."); $stop;
		end
		if(~vpa_i) begin
			$display("CPU should be accessing program space here."); $stop;
		end
		if(stb_i != 2'b11) begin
			$display("Fetching a full word here."); $stop;
		end
		if(adr_i != (`RESET_ORIGIN>>1)+2) begin
			$display("Fetching opcode from wrong address"); $stop;
		end
		
		story_o <= 16'hFFFF;
		$stop;
	end
endmodule
