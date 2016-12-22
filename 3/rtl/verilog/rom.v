`timescale 1ns / 1ps

module ROM(
	input		[19:1]	rom_adr_i,
	output reg	[15:0]	rom_dat_o
);
        reg [15:0] contents[0:8191];

        initial begin
                $readmemh("blockrom.hex", contents);
        end

        always @(rom_adr_i) begin
                rom_dat_o = contents[rom_adr_i];
        end
endmodule
