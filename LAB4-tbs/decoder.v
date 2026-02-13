module decoder(
    input wire [15:0] instr_set,
	 input wire decoder_en,
    output reg [7:0] opcode,
    output reg [3:0] Rdest, Rsrc_Imm,
	 output reg Imm_select,
	 output reg [15:0] imm16
);

	// Decode instruction fields
	wire [3:0] op = instr_set[15:12];   // opcode (4 bits)
	wire [3:0] code_ext = instr_set[7:4];  // extended code (4 bits)
	wire [3:0] Imm_low = instr_set[3:0];   // lower 4 bits of the immediate
	wire [3:0] Imm_high = instr_set[7:4];  // upper 4 bits of the immediate

	// Concatenate Imm_high and Imm_low to form a 16-bit immediate
	assign imm16 = {{8{Imm_high[3]}}, Imm_high, Imm_low};
	
	// if top bits of opcode are not 0, then it is an I-type instruction, otherwise
	// it is an R-type instruction
	assign Imm_select = (op != 4'b0000);

	/*************************************************************************
									Decoder Logic:
	*************************************************************************/
	
	always @(*) begin
		if (op != 4'b0000) begin 
			Imm_select = 1'b1;
		end
		else begin
			Imm_select = 1'b0;
		end
	end
endmodule