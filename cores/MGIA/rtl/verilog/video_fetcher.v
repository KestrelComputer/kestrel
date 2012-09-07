`timescale 1ns / 1ps
module VIDEO_FETCHER(
	input					RST_I,
	input					CLK_I_25MHZ,
	input					VSYNC_I,
	input					VFEN_I,
	output	[12:0]	RAM_ADR_O,
	output				RAM_CYC_O,
	output				RAM_STB_O,
	input					RAM_ACK_I,
	input		[15:0]	RAM_DAT_I,
	output	[ 5:0]	LB_ADR_O,
	output	[15:0]	LB_DAT_O,
	output				LB_WE_O
);

	reg	[12:0]	bitmap_ptr;
	reg				bitmap_fetch_in_progress;

	reg	[12:0]	n_bitmap_ptr;
	reg				n_bitmap_fetch_in_progress;
	reg				last_transfer;
	reg				start_transfer;
	reg	[ 5:0]	fetch_counter;
	reg	[ 5:0]	n_fetch_counter;
	reg				o_vfen;
	reg				rst_fetch_ctr;
	reg				inc_fetch_ctr;
	reg				line_buffer_write;

	assign	RAM_ADR_O	= bitmap_ptr;
	assign	RAM_CYC_O	= bitmap_fetch_in_progress;
	assign	RAM_STB_O	= bitmap_fetch_in_progress;
	assign	LB_ADR_O		= fetch_counter;
	assign	LB_WE_O		= line_buffer_write;
	assign	LB_DAT_O		= RAM_DAT_I;

	always @(posedge CLK_I_25MHZ) begin
		bitmap_ptr						<= n_bitmap_ptr;
		bitmap_fetch_in_progress	<= n_bitmap_fetch_in_progress;
		fetch_counter					<= n_fetch_counter;
		o_vfen							<= VFEN_I;
	end
	
	always @(*) begin
		start_transfer		<= VFEN_I & !o_vfen;
		last_transfer		<= (fetch_counter == 40);
		rst_fetch_ctr		<= (RST_I | last_transfer);
		line_buffer_write	<= RAM_CYC_O & RAM_STB_O & RAM_ACK_I;
		inc_fetch_ctr		<= (bitmap_fetch_in_progress & line_buffer_write);

		case({VSYNC_I, line_buffer_write})
			2'b10:	n_bitmap_ptr <= bitmap_ptr;
			2'b11:	n_bitmap_ptr <= bitmap_ptr+1;
			default:	n_bitmap_ptr <= 0;
		endcase

		case({rst_fetch_ctr, inc_fetch_ctr})
			2'b01:	n_fetch_counter <= fetch_counter+1;
			2'b10:	n_fetch_counter <= 0;
			2'b11:	n_fetch_counter <= 0;
			default:	n_fetch_counter <= fetch_counter;
		endcase

		case({start_transfer, last_transfer})
			3'b01:	n_bitmap_fetch_in_progress <= 0;
			3'b10:	n_bitmap_fetch_in_progress <= !RST_I;
			default:	n_bitmap_fetch_in_progress <= (RST_I)? 0 : bitmap_fetch_in_progress;
		endcase
	end
endmodule
