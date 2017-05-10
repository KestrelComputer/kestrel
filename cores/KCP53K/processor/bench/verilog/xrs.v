`timescale 1ns / 1ps

// This module verifies correct register file behavior.

module test_xrs();
	reg clk_o;
	reg [15:0] story_o;
	wire [63:0] rdat_i;
	reg [63:0] rdat_o;
	reg [4:0] ra_o;
	reg [3:0] rmask_o;

	xrs x(
		.clk_i(clk_o),
		.ra_i(ra_o),
		.rdat_i(rdat_o),
		.rdat_o(rdat_i),
		.rmask_i(rmask_o)
	);

	always begin
		#20 clk_o <= ~clk_o;
	end

	task tick;
	input [15:0] story;
	begin
		story_o <= story;
		@(posedge clk_o);
		@(negedge clk_o);
	end
	endtask

	task assert_rdat;
	input [63:0] expected;
	begin
		if(rdat_i !== expected) begin
			$display("@E %04X RDAT_O Expected $%016X, got $%016X", story_o, expected, rdat_i);
			$stop;
		end
	end
	endtask

	initial begin
		clk_o <= 0;

		// When writing to the register file, we present data and address concurrently.
		// The register will store the provided data at the specified register address
		// upon the next clock edge, as allowed by the mask.
		ra_o <= 0;
		rdat_o <= 64'h0BADC0DE0BADC0DE;
		rmask_o <= 4'b1111;
		tick(16'h0000);

		ra_o <= 1;
		rdat_o <= 64'hDEADBEEFFEEDFACE;
		tick(16'h0001);

		ra_o <= 2;
		rdat_o <= 64'hFEEDFACEDEADBEEF;
		tick(16'h0002);

		// We confirm our writes by trying to read back from the register file.  Note that
		// register 0 must always be 0, even if we "write" something over it.
		ra_o <= 0;
		rmask_o <= 4'b0000;
		tick(16'h0010);
		assert_rdat(0);

		ra_o <= 1;
		tick(16'h0011);
		assert_rdat(64'hDEADBEEFFEEDFACE);

		ra_o <= 2;
		tick(16'h0012);
		assert_rdat(64'hFEEDFACEDEADBEEF);
		
		$display("@DONE");
		$stop;
	end
endmodule
