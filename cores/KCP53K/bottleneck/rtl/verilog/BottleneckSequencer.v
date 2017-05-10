// This hand-written file replaces the SMG-generated file of the same name.

`timescale 1ns / 1ps

module BottleneckSequencer(
	input 	SAckI,
	input 	ack3,
	input 	ack2,
	input 	ack1,
	input 	MAdrI2,
	input 	MAdrI1,
	input 	MAdrI0,
	input 	MSiz0,
	input 	MSiz1,
	input 	MStbI,
	input 	MCycI,
	input 	ResetI,
	output 	SWeO_MWeI,
	output 	SStbO_MStbI,
	output 	SStbO_1,
	output 	SSizO_MSizI0,
	output 	SSizO_1,
	output 	SSignedO_MSignedI,
	output 	SDatO_MDatI63_48,
	output 	SDatO_MDatI47_32,
	output 	SDatO_MDatI31_16,
	output 	SDatO_MDatI,
	output 	plus6,
	output 	plus4,
	output 	plus2,
	output 	SAdrO_MAdrI,
	output 	MErrAlignO_1,
	output 	MDatO_SDatI,
	output 	MAckO_SAckI,
	output 	MAckO_1,
	output 	Hold3_SDatI,
	output 	Hold2_SDatI,
	output 	Hold1_SDatI,
	output 	ack3_o,
	output 	ack2_o,
	output 	ack1_o
);
	reg SWeO_MWeI;
	reg SStbO_MStbI;
	reg SStbO_1;
	reg SSizO_MSizI0;
	reg SSizO_1;
	reg SSignedO_MSignedI;
	reg SDatO_MDatI63_48;
	reg SDatO_MDatI47_32;
	reg SDatO_MDatI31_16;
	reg SDatO_MDatI;
	reg plus6;
	reg plus4;
	reg plus2;
	reg SAdrO_MAdrI;
	reg MErrAlignO_1;
	reg MDatO_SDatI;
	reg MAckO_SAckI;
	reg MAckO_1;
	reg Hold3_SDatI;
	reg Hold2_SDatI;
	reg Hold1_SDatI;
	reg ack3_o;
	reg ack2_o;
	reg ack1_o;

	always @(*) begin
		SWeO_MWeI = 0;
		SStbO_MStbI = 0;
		SStbO_1 = 0;
		SSizO_MSizI0 = 0;
		SSizO_1 = 0;
		SSignedO_MSignedI = 0;
		SDatO_MDatI63_48 = 0;
		SDatO_MDatI47_32 = 0;
		SDatO_MDatI31_16 = 0;
		SDatO_MDatI = 0;
		plus6 = 0;
		plus4 = 0;
		plus2 = 0;
		SAdrO_MAdrI = 0;
		MErrAlignO_1 = 1;	// Unless told otherwise, assume unaligned accesses.
		MDatO_SDatI = 0;
		MAckO_SAckI = 0;
		MAckO_1 = 0;
		Hold3_SDatI = 0;
		Hold2_SDatI = 0;
		Hold1_SDatI = 0;
		ack3_o = 0;
		ack2_o = 0;
		ack1_o = 0;

		// 8-bit accesses

		if (~ResetI && MCycI && MStbI && ~MSiz1 && ~MSiz0) begin
			SAdrO_MAdrI = 1;
			SDatO_MDatI = 1;
			SSignedO_MSignedI = 1;
			SSizO_MSizI0 = 1;
			SStbO_MStbI = 1;
			SWeO_MWeI = 1;
			MAckO_SAckI = 1;
			MDatO_SDatI = 1;
			MErrAlignO_1 = 0;
		end

		// 16-bit accesses

		if (~ResetI && MCycI && MStbI && ~MSiz1 && MSiz0 && ~MAdrI0) begin
			SAdrO_MAdrI = 1;
			SDatO_MDatI = 1;
			SSignedO_MSignedI = 1;
			SSizO_MSizI0 = 1;
			SStbO_MStbI = 1;
			SWeO_MWeI = 1;
			MAckO_SAckI = 1;
			MDatO_SDatI = 1;
			MErrAlignO_1 = 0;
		end

		// 32-bit accesses

		if (~ResetI && MCycI && MStbI && MSiz1 && ~MSiz0 && ~MAdrI1 && ~MAdrI0) begin
			SAdrO_MAdrI = 1;
			SSignedO_MSignedI = 1;
			SSizO_1 = 1;
			SStbO_1 = 1;
			SWeO_MWeI = 1;
			MErrAlignO_1 = 0;

			if (~ack1) begin
				plus2 = 1;
				SDatO_MDatI31_16 = 1;
				Hold1_SDatI = 1;

				if (SAckI) begin
					ack1_o = 1;
				end
			end
			else begin
				SDatO_MDatI = 1;
				MDatO_SDatI = 1;

				if (SAckI) begin
					MAckO_1 = 1;
				end
				else begin
					ack1_o = 1;
				end
			end
		end

		// 64-bit accesses

		if (~ResetI && MCycI && MStbI && MSiz1 && MSiz0 && ~MAdrI2 && ~MAdrI1 && ~MAdrI0 && ~ack1 && ~ack2 && ~ack3) begin
			SAdrO_MAdrI = 1;
			plus6 = 1;
			SDatO_MDatI63_48 = 1;
			SSignedO_MSignedI = 1;
			SSizO_1 = 1;
			SStbO_1 = 1;
			SWeO_MWeI = 1;
			Hold3_SDatI = 1;
			MErrAlignO_1 = 0;

			if (SAckI) begin
				ack3_o = 1;
			end
		end

		if (~ResetI && MCycI && MStbI && MSiz1 && MSiz0 && ~MAdrI2 && ~MAdrI1 && ~MAdrI0 && ~ack1 && ~ack2 && ack3) begin
			SAdrO_MAdrI = 1;
			plus4 = 1;
			SDatO_MDatI47_32 = 1;
			SSignedO_MSignedI = 1;
			SSizO_1 = 1;
			SStbO_1 = 1;
			SWeO_MWeI = 1;
			Hold2_SDatI = 1;
			MErrAlignO_1 = 0;
			ack3_o = 1;

			if (SAckI) begin
				ack2_o = 1;
			end
		end

		if (~ResetI && MCycI && MStbI && MSiz1 && MSiz0 && ~MAdrI2 && ~MAdrI1 && ~MAdrI0 && ~ack1 && ack2 && ack3) begin
			SAdrO_MAdrI = 1;
			plus2 = 1;
			SDatO_MDatI31_16 = 1;
			SSignedO_MSignedI = 1;
			SSizO_1 = 1;
			SStbO_1 = 1;
			SWeO_MWeI = 1;
			Hold1_SDatI = 1;
			MErrAlignO_1 = 0;
			ack2_o = 1;
			ack3_o = 1;

			if (SAckI) begin
				ack1_o = 1;
			end
		end

		if (~ResetI && MCycI && MStbI && MSiz1 && MSiz0 && ~MAdrI2 && ~MAdrI1 && ~MAdrI0 && ack1 && ack2 && ack3) begin
			SAdrO_MAdrI = 1;
			SDatO_MDatI = 1;
			SSignedO_MSignedI = 1;
			SSizO_1 = 1;
			SStbO_1 = 1;
			SWeO_MWeI = 1;
			MDatO_SDatI = 1;
			MErrAlignO_1 = 0;

			if (SAckI) begin
				MAckO_1 = 1;
			end
			else begin
				ack1_o = 1;
				ack2_o = 1;
				ack3_o = 1;
			end
		end
	end
endmodule
