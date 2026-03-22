`timescale 1ns/1ps
module tb_hard_coded_vga();
	reg clk;
	reg rst;
	wire vga_clk;
	wire vga_blank_n;
	wire vga_vs;
	wire vga_hs;
	wire [7:0] r;
	wire [7:0] g;
	wire [7:0] b;
					  
	hard_coded_vga uut (
								.clk(clk), 
							   .rst(rst),
							   .vga_clk(vga_clk),
								.vga_blank_n(vga_blank_n), 
								.vga_vs(vga_vs), 
								.vga_hs(vga_hs),
								.r(r),
								.g(g), 
								.b(b)
							);

    initial begin
        clk = 0;
        rst = 0;
        #10;
        rst = 1;
    end
    always #5 clk = ~clk;
endmodule
