module pc(
	input wire pc_en,
	input wire rst,
	input wire clk,
	input wire[15:0] pc_in,
	output reg[15:0] pc_count
	);

   always @(posedge clk, negedge rst) begin
		if (!rst)
			pc_count <= 16'd0;
		else if (pc_en)
			pc_count <= pc_in;
		
	end
endmodule

