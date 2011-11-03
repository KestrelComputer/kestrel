`timescale 1ns / 1ps
module SHIFTER(
	input					CLK_I_25MHZ,
	input					VREN_I,
	output	[ 5:0]	F_ADR_O,
	input		[15:0]	F_DAT_I,
	output				PEN_O
);

	reg	[ 3:0]	dot_counter;
	reg	[ 5:0]	word_counter;
	reg	[ 3:0]	n_dot_counter;
	reg	[ 5:0]	n_word_counter;
	reg				pen;
	reg				inc_word_counter;

	assign	PEN_O		= pen;
	assign	F_ADR_O	= word_counter;

	always @(posedge CLK_I_25MHZ) begin
		dot_counter			<= n_dot_counter;
		word_counter		<= n_word_counter;
		pen					<= VREN_I & F_DAT_I[~dot_counter[3:0]];
	end

	always @(*) begin
		inc_word_counter	<= (dot_counter[3:0] == 4'hE);
		n_dot_counter <= (VREN_I)? (dot_counter+1) : 0;

		case({VREN_I, inc_word_counter})
			2'b10:	n_word_counter <= word_counter;
			2'b11:	n_word_counter <= word_counter+1;
			default:	n_word_counter <= 0;
		endcase
	end
endmodule
