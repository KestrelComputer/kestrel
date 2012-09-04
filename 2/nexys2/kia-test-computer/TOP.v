`timescale 1ns / 1ps

module TOP(
	output N2_CA_O,
	output N2_CB_O,
	output N2_CC_O,
	output N2_CD_O,
	output N2_CE_O,
	output N2_CF_O,
	output N2_CG_O,
	output N2_DP_O,
	output N2_A0_O,
	output N2_A1_O,
	output N2_A2_O,
	output N2_A3_O,
	output N2_HSYNC_O,
	output N2_VSYNC_O,
	output [2:0] N2_RED_O,
	output [2:0] N2_GRN_O,
	output [2:1] N2_BLU_O,
	input N2_PS2D_I,
	input N2_PS2C_I,
	input N2_50MHZ_I,
	input N2_RST_I
);

	wire	[15:1]	cpu_adr;
	wire				cpu_we;
	wire				cpu_cyc;
	wire				cpu_stb;
	wire	[1:0]		cpu_sel;
	wire				cpu_vda;
	wire				cpu_vpa;
	wire	[15:0]	cpu_dat_o;
	wire	[15:0]	cpu_dat_i;

	reg				cpu_ack;

	reg				led_a;
	reg				led_b;
	reg				led_c;
	reg				led_d;
	reg				led_e;
	reg				led_f;
	reg				led_g;
	reg				led_dp;
	reg				led_anode_0;
	reg				led_anode_1;
	reg				led_anode_2;
	reg				led_anode_3;

	reg				vsync;
	reg				hsync;
	reg	[2:0]		red;
	reg	[2:0]		green;
	reg	[2:1]		blue;

////// CPU //////

	STEAMER16X4 cpu(
		.clk_i(N2_50MHZ_I),
		.res_i(N2_RST_I),
		.adr_o(cpu_adr),
		.we_o (cpu_we),
		.cyc_o(cpu_cyc),
		.stb_o(cpu_stb),
		.sel_o(cpu_sel),
		.vda_o(cpu_vda),
		.vpa_o(cpu_vpa),
		.dat_o(cpu_dat_o),
		.ack_i(cpu_ack),
		.dat_i(cpu_dat_i)
	);

////// ACK generator //////

	always @(posedge N2_50MHZ_I) begin
		if(N2_RST_I) begin
			cpu_ack <= 0;
		end else begin
			cpu_ack <= (~cpu_ack) & cpu_cyc & cpu_stb;
		end
	end

////// SYSTEM RAM //////

	wire	ram_addressed = (cpu_adr[15:12] == 4'h0) & cpu_cyc & cpu_stb;
	wire	ram_even_en = ram_addressed & cpu_sel[0];
	wire	ram_odd_en  = ram_addressed & cpu_sel[1];
	
	RAMB16_S9 progmem_E(
		.CLK(N2_50MHZ_I),
		.WE(cpu_we),
		.EN(ram_even_en),
		.SSR(0),
		.ADDR(cpu_adr[11:1]),
		.DI(cpu_dat_o[7:0]),
		.DO(cpu_dat_i[7:0]),
		.DIP(1)
	);
	
	RAMB16_S9 progmem_O(
		.CLK(N2_50MHZ_I),
		.WE(cpu_we),
		.EN(ram_odd_en),
		.SSR(0),
		.ADDR(cpu_adr[11:1]),
		.DI(cpu_dat_o[15:8]),
		.DO(cpu_dat_i[15:8]),
		.DIP(1)
	);

////// GPIO //////

   assign N2_CA_O = led_a;
   assign N2_CB_O = led_b;
   assign N2_CC_O = led_c;
   assign N2_CD_O = led_d;
   assign N2_CE_O = led_e;
   assign N2_CF_O = led_f;
   assign N2_CG_O = led_g;
   assign N2_DP_O = led_dp;
   assign N2_A0_O = led_anode_0;
   assign N2_A1_O = led_anode_1;
   assign N2_A2_O = led_anode_2;
   assign N2_A3_O = led_anode_3;

	assign N2_VSYNC_O = vsync;
	assign N2_HSYNC_O = hsync;
	assign N2_RED_O = red;
	assign N2_GRN_O = green;
	assign N2_BLU_O = blue;
	
	wire	ledport_addressed = (cpu_adr[15:12] == 4'h1) & cpu_cyc & cpu_stb;

	always @(posedge N2_50MHZ_I) begin
		if(N2_RST_I) begin
			led_a <= 1;				led_e <= 1;
			led_b <= 1;				led_f <= 1;
			led_c <= 1;				led_g <= 1;
			led_d <= 1;				led_dp <= 1;
			led_anode_0 <= 1;		led_anode_1 <= 1;
			led_anode_2 <= 1;		led_anode_3 <= 1;
			vsync <= 1;				hsync <= 1;
			red <= 3'b000;			green <= 3'b000;
			blue <= 2'b00;
		end
		else begin
			if(ledport_addressed & cpu_sel[0]) begin
				led_a <= cpu_dat_o[0];	led_e <= cpu_dat_o[4]; 
				led_b <= cpu_dat_o[1];	led_f <= cpu_dat_o[5];
				led_c <= cpu_dat_o[2];	led_g <= cpu_dat_o[6];
				led_d <= cpu_dat_o[3];	led_dp <= cpu_dat_o[7];
			end
			if(ledport_addressed & cpu_sel[1]) begin
				led_anode_0 <= cpu_dat_o[12];
				led_anode_1 <= cpu_dat_o[13];
				led_anode_2 <= cpu_dat_o[14];
				led_anode_3 <= cpu_dat_o[15];
			end
		end
	end
endmodule
