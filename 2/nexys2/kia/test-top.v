`timescale 1 ns / 1 ps

module TEST_KIA;
	// To test the KIA, we need a Wishbone bus.
	reg 				CLK_O;
	reg 				RES_O;

	// The KIA will communicate with the microprocessor through
	// a typical memory bus interface.
	reg	[0:0]		ADR_O;
	reg				WE_O;
	reg				CYC_O;
	reg				STB_O;
	wire				ACK_I;
	wire	[7:0]		DAT_I;

	// The KIA must also talk to a keyboard.
	reg				C_O;
	reg				D_O;

	// This register is used to identify a specific test in progress.
	// This eases correspondence between waveform traces and their
	// corresponding (successful) tests.
	reg	[15:0]		STORY_O;

	// The KIA under test.
	KIA_M kia(
		.CLK_I(CLK_O),
		.RES_I(RES_O),
		.ADR_I(ADR_O),
		.WE_I(WE_O),
		.CYC_I(CYC_O),
		.STB_I(STB_O),
		.ACK_O(ACK_I),
		.DAT_O(DAT_I),
		
		.D_I(D_O),
		.C_I(C_O)
	);

	always begin
		#50 CLK_O <= ~CLK_O;
	end;

	initial begin
		RES_O <= 0;
		CLK_O <= 0;
		ADR_O <= 0;
		WE_O <= 0;
		CYC_O <= 0;
		STB_O <= 0;
		D_O <= 1;
		C_O <= 1;
		wait(CLK_O);
		wait(~CLK_O);

		// AS A systems programmer
		// I WANT the KIA to report an empty queue after reset
		// SO THAT I can start the operating system with a clean slate.

		STORY_O <= 0;
		RES_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= 0;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(ACK_I != 1) begin
			$display("Single cycle response expected."); $stop;
		end
		if(DAT_I != 8'h01) begin
			$display("Expected queue to be empty."); $stop;
		end

		// AS A systems programmer
		// I WANT the KIA to report a non-empty queue after receiving a keycode
		// SO THAT I can pull the key code from the queue.
		
		STORY_O <= 16'h0010;
		RES_O <= 1;
		CYC_O <= 0;
		STB_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= 0;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(ACK_I != 1) begin
			$display("Single cycle response expected."); $stop;
		end
		if(DAT_I != 8'h00) begin
			$display("Expected queue to be neither full nor empty."); $stop;
		end

		// AS A systems programmer
		// I WANT the keyboard queue to faithfully record the received scan code
		// SO THAT I can respond intelligently to user input.

		STORY_O <= 16'h0020;
		RES_O <= 1;
		CYC_O <= 0;
		STB_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= 1;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(ACK_I != 1) begin
			$display("Single cycle response expected."); $stop;
		end
		if(DAT_I != 8'h1B) begin
			$display("Head of the queue doesn't have the right data byte."); $stop;
		end

		// AS A systems programmer
		// I WANT the queue to capture multiple data bytes while I'm busy
		// SO THAT I don't have to have such stringent real-time requirements.
		
		STORY_O <= 16'h0030;
		RES_O <= 1;
		CYC_O <= 0;
		STB_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		RES_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= 1;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(ACK_I != 1) begin
			$display("Single cycle response expected."); $stop;
		end
		if(DAT_I != 8'hE0) begin
			$display("Expected 8'hE0 for first byte."); $stop;
		end
		ADR_O <= 0;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= 1;
		WE_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h1B) begin
			$display("Expected 8'h1B for second byte."); $stop;
		end

		// AS A verilog engineer
		// I WANT the end of all tests to be delineated on the waveform
		// SO THAT I don't have to hunt around for the end of the test sequence.

		STORY_O <= -1;
		wait(CLK_O); wait(~CLK_O);
	end;
endmodule
