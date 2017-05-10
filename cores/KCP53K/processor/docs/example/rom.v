`timescale 1ns / 1ps

module rom(
	input	[11:3]	A,	// Address
	output	[63:0]	Q,	// Data output
	input	STB		// True if ROM is being accessed.
);
	reg [63:0] contents[0:511];
	wire [63:0] results = contents[A];
	assign Q = STB ? results : 0;

	initial begin
		$readmemh("example.hex", contents);
	end
endmodule

