`timescale 1ns / 1ps
module LINE_BUFFERS(
	input					CLK_I,
	input					ODD_I,
	input		[ 5:0]	F_ADR_I,
	output	[15:0]	F_DAT_O,
	input		[ 5:0]	S_ADR_I,
	input		[15:0]	S_DAT_I,
	input					S_WE_I
);

	reg	[15:0]	line_a[0:63];
	reg	[15:0]	line_b[0:63];
	reg	[15:0]	f_q;

	assign	F_DAT_O = f_q;

	always @(posedge CLK_I) begin
		f_q <= (ODD_I)? line_b[F_ADR_I] : line_a[F_ADR_I];
		if(S_WE_I & ODD_I)	line_a[S_ADR_I] <= S_DAT_I;
		if(S_WE_I & !ODD_I)	line_b[S_ADR_I] <= S_DAT_I;
	end
endmodule
