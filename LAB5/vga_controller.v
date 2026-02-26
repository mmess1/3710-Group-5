module vga_controller (
	input	wire      vga_clk, // This assumes you are giving a 25 MHz clock from the clock divider
	input wire          rst,
	output wire      vga_hs, 
	output wire      vga_vs,
	output wire vga_blank_n, 	// can draw or not
	output reg [9:0] hcount,	// current x cordinate
	output reg [9:0] vcount		// current y cordinate
);

// Parameters for a VGA display resolution of 640 x 480 pixels (at a 60Hz refresh rate so 60 frames/second) display
// dropping our 50MHz clock to a 25MHz pixel clock (because 800 pixels/line * 525 lines/frame * 60 frames/second = 
// 25.2M pixels/second = 25.2MHz vga clock, but we'll use 25MHz vga clock)

// NOTE: Because we will use a 25MHz VGA clock instead of 25.2MHz the calculations below are slightly off 
// -- you may change this if you want BUT it should be fine for your Lab 5 check offs.

parameter H_SYNC        = 10'd96;  // Horizontal Sync Region -- 96 pixels
parameter H_BACK_PORCH  = 10'd48;  // Horizontal Back Porch -- 48 pixels
parameter H_DISPLAY     = 10'd640; // Horizontal Display Region -- 640 pixels
parameter H_FRONT_PORCH = 10'd16;  // Horizontal Front Porch -- 16 pixels
parameter H_TOTAL       = 10'd800; // Horizontal Total Width -- 96 + 16 + 640 + 48 = 800 pixels

parameter V_SYNC        = 10'd2;   // Vertical Sync Region -- 2 lines
parameter V_BACK_PORCH  = 10'd33;  // Vertical Back Porch -- 33 lines
parameter V_DISPLAY     = 10'd480; // Vertical Display Region -- 480 lines
parameter V_FRONT_PORCH = 10'd10;  // Vertical Front Porch -- 10 lines
parameter V_TOTAL       = 10'd525; // Vertical Total Width -- 2 + 33 + 480 + 10 = 525 lines

// This always block keeps your hcount (which pixel in the line you are on) and vcount (which line you are on).
always @(posedge vga_clk, negedge rst) begin
    if (~rst) begin
        hcount <= 10'd0;
        vcount <= 10'd0;
    end
	 
	 /* Remember hcount will go from 0 to 799 for the 800 pixels and vcount will go to 525 lines.
		hcount sets back to zero at the end of a line.
		Vcount only updates after a line of pixels, vcount sets back to zero after a full frame.
		TO DO: WRITE THE NESTED LOOPS TO KEEP TRACK OF VCOUNT AND HCOUNT
	 */ 
	   // Increment hcount (pixel position on the current line)
     if (hcount < 799) begin
            hcount <= hcount + 1;
     end else begin
        hcount <= 10'd0; // Reset hcount after 800 pixels (end of line)
            
        // Increment vcount only once hcount = 800
        if (vcount < 524) begin
                vcount <= vcount + 1;
            end else begin
                vcount <= 10'd0; // Reset vcount after 525 lines (end of frame)
            end
        end
    end
end
	 


// vga_hs is active LOW, so it should be 0 during the horizontal sync (H_SYNC) also know as the pulse region.
// Otherwise, vga_hs should be 1 during. Recall hcount keeps track of what pixel you are at in a line.
// TO DO: FILL IN WHAT BOOLEAN FUNCTION DESCRIBES VGA_HS
// HINT: HCOUNT TELLS WHICH PIXEL IN A LINE YOU ARE AT -- IS IT IN THE H SYNC REGION???????

// [visible area (640)] --> [front Porch (16)] --> [Horizontal Sync (96)] --> [back Porch (48) ]
// Pixels:      (0 - 640)             (641 - 656)                 (689 - 784)          (785 - 800)
 
 assign vga_hs = (hcount <= (H_DISPLAY + H_FRONT_PORCH))) | (hcount >= (H_TOTAL - H_BACK_PORCH));
 

// vga_vs is active LOW, so it should be 0 during the vertical sync (V_SYNC) also know as the pulse region.
// Recall vcount keeps track of what line you are at.
// TO DO: FILL IN WHAT BOOLEAN FUNCTION DESCRIBES VGA_VS
// HINT: VCOUNT TELLS WHICH LINE IN A FRAM YOU ARE AT -- IS IT IN THE V SYNC REGION???????

// [visible area (480)] --> [front Porch (10)] --> [Vertical Sync (2)] --> [back Porch (33) ]
// Pixels:      (0 - 480)             (641 - 688)             (689 - 784)          (785 - 800)

assign vga_vs = (vcount <= (V_DISPLAY + V_FRONT_PORCH))) | (vcount >= (V_TOTAL - V_BACK_PORCH));

// vga_blank_n is active LOW during blank regions (porches and syncs), and HIGH during video transmission. 
// TO DO: FILL IN WHAT BOOLEAN FUNCTION DESCRIBES VGA_BLANK_N

assign vga_blank_n = (hcount < H_DISPLAY)) & (vcount < V_DISPLAY);


endmodule
