module paddles(
    input wire vga_clk,              // VGA clock signal
    input wire [9:0] hcount,         // Horizontal pixel counter
    input wire [9:0] vcount,         // Vertical pixel counter
    input wire [8:0] player1_y_pos, // Player 1 paddle Y position
    input wire [8:0] player2_y_pos, // Player 2 paddle Y position
    output reg [23:0] rgb           // RGB output for the VGA display
);

    // Constants for paddle dimensions and positions
    parameter PADDLE_WIDTH = 10;    // Paddle width (in pixels)
    parameter PADDLE_HEIGHT = 45;   // Paddle height (in pixels)

    // Player paddle X positions (fixed)
    parameter PLAYER1_X = 150;   // Player 1 is on the left side (set to 150 for visibility)
    parameter PLAYER2_X = 610;  // Player 2 is on the right side

    // VGA timing parameters
    parameter H_SYNC        = 10'd96;   // Horizontal Sync Region -- 96 pixels
    parameter H_BACK_PORCH  = 10'd48;   // Horizontal Back Porch -- 48 pixels
    parameter H_DISPLAY     = 10'd640;  // Horizontal Display Region -- 640 pixels
    parameter H_FRONT_PORCH = 10'd16;   // Horizontal Front Porch -- 16 pixels
    parameter H_TOTAL       = 10'd800;  // Horizontal Total Width -- 96 + 16 + 640 + 48 = 800 pixels

    parameter V_SYNC        = 10'd2;    // Vertical Sync Region -- 2 lines
    parameter V_BACK_PORCH  = 10'd33;   // Vertical Back Porch -- 33 lines
    parameter V_DISPLAY     = 10'd480;  // Vertical Display Region -- 480 lines
    parameter V_FRONT_PORCH = 10'd10;   // Vertical Front Porch -- 10 lines
    parameter V_TOTAL       = 10'd525;  // Vertical Total Width -- 2 + 33 + 480 + 10 = 525 lines

    // Color Definitions
    parameter WHITE = 24'b111111_111111_111111;  // White color for paddles
    parameter BLACK = 24'b000000_000000_000000;  // Black background color

    // Always block triggered by the VGA clock signal
    always @(posedge vga_clk) begin
        rgb = BLACK;  // Default to black (background color)

        // Check if the current pixel is within the visible display area
        if ((hcount >= (H_SYNC + H_BACK_PORCH)) && (hcount < (H_SYNC + H_BACK_PORCH + H_DISPLAY)) &&
            (vcount >= (V_SYNC + V_BACK_PORCH)) && (vcount < (V_SYNC + V_BACK_PORCH + V_DISPLAY))) begin
            // Check if the current pixel is within Player 1's paddle area
            if ((hcount >= PLAYER1_X) && (hcount < PLAYER1_X + PADDLE_WIDTH) && 
                (vcount >= player1_y_pos) && (vcount < player1_y_pos + PADDLE_HEIGHT)) begin
                rgb = WHITE;  // Draw Player 1's paddle in white
            end
            // Check if the current pixel is within Player 2's paddle area
            else if ((hcount >= PLAYER2_X) && (hcount < PLAYER2_X + PADDLE_WIDTH) && 
                     (vcount >= player2_y_pos) && (vcount < player2_y_pos + PADDLE_HEIGHT)) begin
                rgb = WHITE;  // Draw Player 2's paddle in white
            end
        end
    end

endmodule