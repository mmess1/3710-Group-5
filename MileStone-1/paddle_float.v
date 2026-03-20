module paddle_float(
    input clk,             // System clock signal (typically CLOCK_50)
    input rst,             // Reset signal
    output reg [8:0] y_pos  // Y position of the paddle
);

    // Clock divider parameters
    localparam COUNT = 1250000;  // Adjust this value to control paddle movement speed (e.g., 1Hz or 20Hz)
    reg [20:0] counter;          // Counter for generating timing signal
    reg tick;                    // Timing signal (1 Hz, or the desired frequency)

    // Clock divider for paddle movement timing (slows down the movement)
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            counter <= 0;
            tick <= 0;
        end else if (counter == COUNT) begin
            counter <= 0;
            tick <= 1;  // Enable tick signal every COUNT cycles
        end else begin
            counter <= counter + 1;
            tick <= 0;
        end
    end

    // Up/Down movement logic
    reg up, down;

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            y_pos <= 150;  // Reset to middle position (e.g., center of the screen)
        end else if( tick) begin
            // Determine if the paddle should move up or down
            if (y_pos <= 150) begin
              down <= 1;
				  up <=0;
				  end
				  if (y_pos >= 350) begin
              down <= 0;
				  up <=1;
				  end
				  if (down) begin
					y_pos <= y_pos + 1;  // Move down
				  end
				  if (up) begin
					y_pos <= y_pos - 1;  // Move down
				  end
				  
    end
	 end
endmodule