module pc(
	input wire pc_en,
	input wire rst,
	input wire clk,
	
	output reg[15:0] pc_count
	);
	

   always @(posedge clk, negedge rst) begin
		if (!rst)
			pc_count <= 16'd0;
		else if (pc_en)
			pc_count <= pc_count + 16'd1;
	end
endmodule