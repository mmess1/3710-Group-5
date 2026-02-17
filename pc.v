module pc(
	input wire pc_en,
	input wire rst,
	input wire clk,
	input reg[15:0] pc_in,
	output reg[15:0] pc_count
	);

   always @(posedge clk, posedge rst) begin
		if (rst)
			pc_count <= 16'd0;
		else if (pc_en)
			pc_count <= pc_in;
		
	end
endmodule

module pc_inc(
    input wire [15:0] in,   // 16-bit input A
    input wire [15:0]k,   // 16-bit input K
    output wire [15:0] sum // 16-bit sum output
);
    // Perform the addition
    assign sum = in + k;  // Simple addition of the two 16-bit inputs
endmodule