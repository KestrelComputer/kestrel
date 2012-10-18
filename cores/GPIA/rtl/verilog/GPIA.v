`timescale 1ns / 1ps

module GPIA(
	input					RST_I,
	input					CLK_I,
	output	[15:0]	PORT_O,
	input		[15:0]	PORT_I,
	
	input					ADR_I,
	input					CYC_I,
	input					STB_I,
	input					WE_I,
	input		[15:0]	DAT_I,
	output	[15:0]	DAT_O,
	output				ACK_O
);

	reg		[15:0]	outputs;
	reg		[15:0]	next_outputs;
	reg		[15:0]	data;
	reg		[15:0]	next_data;
	reg					ack;
	reg					next_ack;

	wire					gpia_addressed = (CYC_I & STB_I);
	wire					output_we = (gpia_addressed & ADR_I & WE_I);
	wire					output_oe = (gpia_addressed & ADR_I & ~WE_I);
	wire					input_oe = (gpia_addressed & ~ADR_I & ~WE_I);

	assign PORT_O	= outputs;
	assign ACK_O	= ack;
	assign DAT_O	= data;

	always @(*) begin
		next_outputs = RST_I ? 16'h0000 : (output_we ? DAT_I : outputs);
		next_data = RST_I ? 0 : (output_oe ? outputs : (input_oe ? PORT_I : 0));
		next_ack = gpia_addressed & ~ack;
	end

	always @(posedge CLK_I) begin
		outputs <= next_outputs;
		data <= next_data;
		ack <= next_ack;
	end
endmodule
