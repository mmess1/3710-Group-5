`timescale 1ns/1ps
module milestone1_tb();
	reg clk;
	reg rst;
	wire vga_clk;
	wire vga_blank_n;
	wire vga_vs;
	wire vga_hs;
	wire [7:0] r;
	wire [7:0] g;
	wire [7:0] b;
					  
	game_display uut (
								.CLOCK_50(clk), 
							   .rst(rst),
							   .VGA_CLK(vga_clk),
								.VGA_BLANK_N(vga_blank_n), 
								.VGA_VS(vga_vs), 
								.VGA_HS(vga_hs),
								.VGA_R(r),
								.VGA_G(g), 
								.VGA_B(b)
							);

    initial begin
        clk = 0;
        rst = 0;
        #10;
        rst = 1;
    end
    always #5 clk = ~clk;
endmodule