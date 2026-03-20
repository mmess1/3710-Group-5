module game_display(
	input wire CLOCK_50, 
	input wire [3:0] KEY,
	output wire VGA_CLK,
	output wire VGA_BLANK_N, 
	output wire VGA_VS, 
	output wire VGA_HS,
	output reg [7:0] VGA_R,
	output reg [7:0] VGA_G, 
	output reg [7:0] VGA_B
);

wire rst = KEY[0];
wire [9:0] hcount, vcount;
wire [3:0] count;
wire [8:0] y_pos1, y_pos2;
	 
clk_divider clk_div
(
	.clk(CLOCK_50), 
	.rst(rst),
	.div_clk(VGA_CLK)
);

vga_controller vga_ctrl (
	.vga_clk(VGA_CLK),  
	.rst(rst),						
	.vga_hs(VGA_HS),
	.vga_vs(VGA_VS),			
	.vga_blank_n(VGA_BLANK_N),	
	.hcount(hcount),						
	.vcount(vcount)						
);


// Declare wire to connect the background rgb output
wire [23:0] background_rgb;

backgound backgound (

    .vga_blank_n(VGA_BLANK_N),
	 .vga_clk(VGA_CLK),
    .hcount(hcount),
    .vcount(vcount),
    .rgb(background_rgb)
);

    // Paddle drawing module
    wire [23:0] paddle_rgb;  // RGB output for paddles
  paddles paddle (
        //.vga_blank_n(VGA_BLANK_N),
		  .vga_clk(VGA_CLK),
        .hcount(hcount),
        .vcount(vcount),
        .player1_y_pos(y_pos1),
        .player2_y_pos(y_pos2),
        .rgb(paddle_rgb)
    );
	 
paddle_float paddle_float1(
    .clk(CLOCK_50),         // System clock
   .rst(rst),         // Reset signal to reset paddle position
    .y_pos(y_pos1)  // Y position of the paddle
);
paddle_float paddle_float2(
    .clk(CLOCK_50),         // System clock
   .rst(rst),         // Reset signal to reset paddle position
    .y_pos(y_pos2)  // Y position of the paddle
);

    // Final RGB output (combine background and paddles)
    always @(posedge VGA_CLK or negedge rst) begin
        if (~rst) begin
            {VGA_R, VGA_G, VGA_B} <= 24'b000000_000000_000000;  // Default to black on reset
        end else begin
            // If the paddle is drawn, use paddle color, otherwise use background color
            {VGA_R, VGA_G, VGA_B} <= (paddle_rgb != 24'b000000_000000_000000) ? paddle_rgb : background_rgb;
        end
    end

endmodule
