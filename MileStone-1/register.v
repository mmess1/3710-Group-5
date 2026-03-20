module register
#(parameter WIDTH = 9)
(
	input wire             clk, 
	input wire             rst,
	input wire              en,
	input wire [(WIDTH-1):0] d,
	output reg [(WIDTH-1):0] q
);

always @(posedge clk, negedge rst) begin

	if (~rst) 		q <= 'd0;
	else if (en) 	q <= d;
	else 				q <= q;

end

endmodule
