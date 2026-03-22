module block_mover (
    input vga_clk,
    input rst,
    output reg [9:0] block_x_offset
);

	localparam COUNT = 1250000; // Adjust as needed
	reg [20:0] counter;
	reg tick;
	
	 // Clock divider for movement timing
    always @(posedge vga_clk) begin
        if (~rst) begin
            counter <= 0;
            tick <= 0;
        end else if (counter == COUNT) begin
            counter <= 0;
            tick <= 1;
        end else begin
            counter <= counter + 1;
            tick <= 0;
        end
    end

    // Move block horizontally
    always @(posedge vga_clk, negedge rst) begin
        if (~rst) begin
				block_x_offset <= 0;
		  end   
        else if (tick) begin
            if (block_x_offset < 400) begin
                block_x_offset <= block_x_offset + 1;
				end
            else begin
                block_x_offset <= 0;
				end
        end
    end

endmodule
