module hard_coded_vga
(
	input wire clk, 
	input wire rst,
	output wire vga_clk,
	output wire vga_blank_n, 
	output wire vga_vs, 
	output wire vga_hs,
	output wire [7:0] r,
	output wire [7:0] g, 
	output wire [7:0] b
);

wire [9:0] hcount, vcount, block_x_offset;
wire [3:0] count;

clk_divider clk_div
(
	.clk(clk), 
	.rst(rst),
	.div_clk(vga_clk)
);

vga_controller vga_ctrl (
	.vga_clk(vga_clk), 
	.rst(rst),						
	.vga_hs(vga_hs),
	.vga_vs(vga_vs),			
	.vga_blank_n(vga_blank_n),	
	.hcount(hcount),						
	.vcount(vcount)						
);

block_mover block_mov (
    .vga_clk(vga_clk),
    .rst(rst),
    .block_x_offset(block_x_offset)
);

hard_coded_bitgen blockgen_inst (
    .vga_blank_n(vga_blank_n),
    .hcount(hcount),
    .vcount(vcount),
	 .block_x_offset(block_x_offset),
    .rgb({r,g,b})
);

endmodule
