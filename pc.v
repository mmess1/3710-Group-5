module pc(
	input wire pc_en;
	input wire rst;
	input wire clk;
	
	output wire[31:0] pc_count;
	);
	

   always @(posedge clk, posedge rst) begin
		if (rst)
			pc_count <= 32'd0;
		else if (pc_en)
			pc_count <= pc_count + 32'd1;
		end
	end
endmodule