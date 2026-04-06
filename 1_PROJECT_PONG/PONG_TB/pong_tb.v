`timescale 1ns/1ps
module pong_tb();
    reg        CLOCK_50,
    reg [3:0]  KEY;
	 wire [35:0] GPIO_1;

    wire [9:0] LEDR;

    wire       ADC_CS_N;
    wire       ADC_DIN;
    wire       ADC_DOUT;
    wire       ADC_SCLK;

    wire [6:0] HEX0;
    wire [6:0] HEX1;
    wire [6:0] HEX2;
    wire [6:0] HEX3;
    wire [6:0] HEX4;
    wire [6:0] HEX5;

    wire       VGA_CLK;
    wire       VGA_BLANK_N;
    wire       VGA_SYNC_N;
    wire       VGA_VS;
    wire       VGA_HS;
    wire [7:0] VGA_R;
    wire [7:0] VGA_G;
    wire [7:0] VGA_B;
					  
	PONG_TOP uPONG_TOP (
								.CLOCK_50(CLOCK_50),
								.KEY(KEY), 
							   .GPIO_1(GPIO_1),
								.ADC_CS_N(ADC_CS_N),
								.ADC_DIN(ADC_DIN),
								.ADC_DOUT(ADC_DOUT),
								.ADC_SCLK(ADC_SCLK),
							   .LEDR(LEDR),
								.HEX0(HEX0), 
								.HEX1(HEX1), 
								.HEX2(HEX2),
								.HEX3(HEX3),
								.HEX4(HEX4), 
								.HEX5(HEX5),
								.VGA_CLK(VGA_CLK),
								.VGA_BLANK_N(VGA_BLANK_N),
								.VGA_SYNC_N(VGA_SYNC_N),
								.VGA_VS(VGA_VS),
								.VGA_HS(VGA_HS),
								.VGA_R(VGA_R),
								.VGA_G(VGA_G),
								.VGA_B(VGA_B)
							);
	initial begin
		 CLOCK_50 = 0;
		 KEY = 4'b0000;  
		 #10;
		 KEY = 4'b1111; 
	end
    always #5 CLOCK_50 = ~CLOCK_50;
endmodule
