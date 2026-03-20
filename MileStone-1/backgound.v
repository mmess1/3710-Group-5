//////////////////////////////////////////////////////////////////////////////////
// File Name:       backgound.v                                                  //
// Description:     VGA controller to generate a black background with a          //
//                  yellow border and a dotted white line down the middle.        //
//                  This module generates RGB signals based on pixel position     //
//                  (hcount, vcount) for VGA display.                             //
//                                                                                //
// Parameters:     - None                                                         //
// Inputs:         - vga_blank_n: VGA blank signal                                //
//                  - hcount: Horizontal pixel count (0-639)                      //
//                  - vcount: Vertical pixel count (0-479)                        //
// Outputs:        - rgb: 24-bit RGB signal (8 bits for each color component)     //
//                                                                                //
// Dependencies:    - None                                                        //
//                                                                                //
// Revision History: 
                                                            
// Date:           3/18/26 (aliou tippett)                                       //
// Description:    initial creation //
//                                                                               //
//////////////////////////////////////////////////////////////////////////////////

module backgound (
    input wire          vga_blank_n, vga_clk,
    input wire [9:0]    hcount, 
    input wire [9:0]    vcount,
    output reg [23:0]   rgb
);

    reg [7:0] r, g, b;
    
    wire [9:0] x_pos, y_pos;
    assign x_pos = hcount;
    assign y_pos = vcount;

    always @(posedge vga_clk) begin
        // Default background color: black
        r <= 8'b00000000;
        g <= 8'b00000000;
        b <= 8'b00000000;

        if (vga_blank_n) begin
		  
            // Draw Yellow Border (top, bottom, left, right)
            if (x_pos < 10 || x_pos >= 630 || y_pos < 10 || y_pos >= 470) begin
                r <= 8'd255;  // Red component of yellow
                g <= 8'd255;  // Green component of yellow
                b <= 8'd0;    // Blue component of yellow
            end
            // Draw dotted white line in the middle
            else if (x_pos == 320 && y_pos % 20 < 10) begin
                r <= 8'd255;  // Red component of white
                g <= 8'd255;  // Green component of white
                b <= 8'd255;  // Blue component of white
            end
            // Default black background
            else begin
                r <= 8'd0;
                g <= 8'd0;
                b <= 8'd0;
            end
        end
        // Concatenate the r, g, b into the 24-bit rgb output
        rgb <= {r, g, b};
    end

endmodule