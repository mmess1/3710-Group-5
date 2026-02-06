module decoder(
	
	input wire[31:0] instr_set;
	input wire clk, reset,

	
   output [15:0] wEnable, Imm_in,
   output wire [7:0] opcode, 
   output wire [3:0] Rdest, Rsrc_Imm,
	output wire Imm_select
);
	wire[3:0] op = instr_set[15:12];
	wire[3:0] code = instr_set[7:4];
	assign opcode = instr_set{op, code};
	assign Rdest = instr_set[11-8];
	assign Rsrc_Imm = instr_set[3:0];
	
endmodule	