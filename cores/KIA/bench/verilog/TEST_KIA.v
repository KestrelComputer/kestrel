`timescale 1 ns / 1 ps

//
// KIA registers
//

`define KQSTAT		0
`define KQDATA		1

// KIA status flag bits

`define KQSF_EMPTY 8'h01
`define KQSF_FULL  8'h02


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
	KIA kia(
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
		ADR_O <= `KQSTAT;
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
		ADR_O <= `KQSTAT;
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
		ADR_O <= `KQSTAT;
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
		ADR_O <= `KQDATA;
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
		ADR_O <= `KQDATA;
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
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		ADR_O <= `KQDATA;
		WE_O <= 0;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h1B) begin
			$display("Expected 8'h1B for second byte."); $stop;
		end

		// AS A verilog engineer
		// I WANT the KIA to drop excess characters when the queue is full
		// SO THAT software engineers don't have to worry about key-code order issues.
		
		STORY_O <= 16'h0040;
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
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
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
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
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
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
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
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		wait(CLK_O); wait(~CLK_O);
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE0) begin
			$display("Pattern mismatch on byte 0."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE1) begin
			$display("Pattern mismatch on byte 1."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE2) begin
			$display("Pattern mismatch on byte 2."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE3) begin
			$display("Pattern mismatch on byte 3."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE4) begin
			$display("Pattern mismatch on byte 4."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE5) begin
			$display("Pattern mismatch on byte 5."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE6) begin
			$display("Pattern mismatch on byte 6."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE7) begin
			$display("Pattern mismatch on byte 7."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE8) begin
			$display("Pattern mismatch on byte 8."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hE9) begin
			$display("Pattern mismatch on byte 9."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hEA) begin
			$display("Pattern mismatch on byte A."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hEB) begin
			$display("Pattern mismatch on byte B."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hEC) begin
			$display("Pattern mismatch on byte C."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hED) begin
			$display("Pattern mismatch on byte D."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hEE) begin
			$display("Pattern mismatch on byte E."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hCF) begin
			$display("Pattern mismatch on byte F."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		ADR_O <= `KQDATA;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'hCF) begin
			$display("Should not be able to read beyond the bottom of the queue."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		
		// AS A software engineer
		// I WANT the KIA to indicate the queue is empty after reading the last available byte
		// SO THAT my keyboard handling loops have an exit criterion.
		
		STORY_O <= 16'h0050;
		RES_O <= 1;
		CYC_O <= 0;
		STB_O <= 0;
		WE_O <= 0;
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
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
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
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
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
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
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
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 0; #32768 C_O <= 0; #32768 C_O <= 1;
		D_O <= 1; #32768 C_O <= 0; #32768 C_O <= 1;

		wait(CLK_O); wait(~CLK_O);
		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != `KQSF_FULL) begin
			$display("Before popping first byte, queue must be full."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 1."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 2."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 3."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 4."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 5."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 6."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 7."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 8."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte 9."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte A."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte B."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte C."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte D."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != 8'h00) begin
			$display("Queue is neither full nor empty.  Byte E."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != `KQSF_EMPTY) begin
			$display("After reading 15 bytes, the queue should be empty."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		ADR_O <= `KQSTAT;
		WE_O <= 0;
		CYC_O <= 1;
		STB_O <= 1;
		wait(CLK_O); wait(~CLK_O);
		if(DAT_I != `KQSF_EMPTY) begin
			$display("Popping an empty queue should have no effect."); $stop;
		end
		ADR_O <= `KQDATA;
		WE_O <= 1;
		wait(CLK_O); wait(~CLK_O);

		// AS A verilog engineer
		// I WANT the end of all tests to be delineated on the waveform
		// SO THAT I don't have to hunt around for the end of the test sequence.

		STORY_O <= -1;
		wait(CLK_O); wait(~CLK_O);
		$stop;
	end;
endmodule
