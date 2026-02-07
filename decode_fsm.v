module decoder(
	
	input wire[15:0] instr_set;
	input wire clk, reset,Imm_select,

	
   output [15:0] wEnable, Imm_in,
   output wire [7:0] opcode, 
   output wire [3:0] Rdest, Rsrc_Imm,
	output wire Imm_select
);
	wire[3:0] op = instr_set[15:12];
	wire[3:0] code_ext = instr_set[7:4];
	assign opcode = instr_set{op, code_ext};
	assign Rdest = instr_set[11-8];
	assign Rsrc_Imm = instr_set[3:0];
	
	wire [3:0]Imm_low;	
	wire [3:0]Imm_high;	
	wire [15:0] imm16; 
	
	
	
	
	
	
	// INSTRUCTIONS:

/*	
	localparam [7:0] ADD   = 8'b0000_0101;
   localparam [7:0] ADDU  = 8'b0000_0110;
   localparam [7:0] ADDC  = 8'b0000_0111;

   localparam [7:0] ADDI  = 8'b0101_xxxx;
   localparam [7:0] ADDUI = 8'b0110_xxxx;
   localparam [7:0] ADDCI = 8'b0111_xxxx;

    localparam [7:0] MOV   = 8'b0000_1101;
    localparam [7:0] MOVI  = 8'b1101_xxxx;

    localparam [7:0] MUL   = 8'b0000_1110;
    localparam [7:0] MULI  = 8'b1110_xxxx;

    localparam [7:0] SUB   = 8'b0000_1001;
    localparam [7:0] SUBC  = 8'b0000_1010;
    localparam [7:0] SUBI  = 8'b1001_xxxx;
    localparam [7:0] SUBCI = 8'b1010_xxxx;

    localparam [7:0] CMP   = 8'b0000_1011;
    localparam [7:0] CMPI  = 8'b1011_xxxx;

    localparam [7:0] AND   = 8'b0000_0001;
    localparam [7:0] OR    = 8'b0000_0010;
    localparam [7:0] XOR   = 8'b0000_0011;
    localparam [7:0] NOT   = 8'b0000_0100;

    localparam [7:0] LSH   = 8'b0000_1100;
    localparam [7:0] LSHI  = 8'b1100_xxxx;

    localparam [7:0] RSH   = 8'b0000_1000;
    localparam [7:0] RSHI  = 8'b1000_xxxx;

    localparam [7:0] ARSH  = 8'b0000_1111;
    localparam [7:0] ARSHI = 8'b1111_xxxx;

    localparam [7:0] WAIT  = 8'b0000_0000;
	 */
	 
localparam [15:0] ADD   = 16'b0000_xxxx_0101_xxxx;
localparam [15:0] ADDU  = 16'b0000_xxxx_0110_xxxx;
localparam [15:0] ADDC  = 16'b0000_xxxx_0111_xxxx;

localparam [15:0] ADDI  = 16'b0101_xxxx_xxxx_xxxx;
localparam [15:0] ADDUI = 16'b0110_xxxx_xxxx_xxxx;
localparam [15:0] ADDCI = 16'b0111_xxxx_xxxx_xxxx;

localparam [15:0] MOV   = 16'b0000_xxxx_1101_xxxx;
localparam [15:0] MOVI  = 16'b1101_xxxx_xxxx_xxxx;

localparam [15:0] MUL   = 16'b0000_xxxx_1110_xxxx;
localparam [15:0] MULI  = 16'b1110_xxxx_xxxx_xxxx;

localparam [15:0] SUB   = 16'b0000_xxxx_1001_xxxx;
localparam [15:0] SUBC  = 16'b0000_xxxx_1010_xxxx;
localparam [15:0] SUBI  = 16'b1001_xxxx_xxxx_xxxx;
localparam [15:0] SUBCI = 16'b1010_xxxx_xxxx_xxxx;

localparam [15:0] CMP   = 16'b0000_xxxx_1011_xxxx;
localparam [15:0] CMPI  = 16'b1011_xxxx_xxxx_xxxx;

localparam [15:0] AND   = 16'b0000_xxxx_0001_xxxx;
localparam [15:0] OR    = 16'b0000_xxxx_0010_xxxx;
localparam [15:0] XOR   = 16'b0000_xxxx_0011_xxxx;
localparam [15:0] NOT   = 16'b0000_xxxx_0100_xxxx;

localparam [15:0] LSH   = 16'b0000_xxxx_1100_xxxx;
localparam [15:0] LSHI  = 16'b1100_xxxx_xxxx_xxxx;

localparam [15:0] RSH   = 16'b0000_xxxx_1000_xxxx;
localparam [15:0] RSHI  = 16'b1000_xxxx_xxxx_xxxx;

localparam [15:0] ARSH  = 16'b0000_xxxx_1111_xxxx;
localparam [15:0] ARSHI = 16'b1111_xxxx_xxxx_xxxx;

localparam [15:0] WAIT  = 16'b0000_xxxx_0000_xxxx;

	
	
/*************************************************************************
							cases:
************************************************************************/
	        // TODO: implement signed ADD
	
	always @* begin

	
	assign Imm_low = instr_set[3:0];
	assign Imm_how = instr_set[7:4];
	assign imm16 = {{8{Imm_high[3]}}, Imm_high, Imm_low}; // 16 bit value for Imm value
	
	op = instr_set[15:12];
	code_ext = instr_set[7:4];
	opcode = instr_set{op, code_ext};
	Rdest = instr_set[11-8];
	Rsrc_Imm = instr_set[3:0];
	Imm_select = 0;
			
  casex (Opcode)
	 

    ADD, ADDU, ADDC, SUB, SUBI, SUBC, SUBCI, MUL, CMP: begin // TODO: arithmetic ops end
	 
	
	 end
	 
	 ADDI, ADDCI, ADDUI, SUBI, SUBCI, MULI, CMPI: begin
	 
	 
		Imm_select = 1;

	 end
	 
    MOV, MOVI:                                                         begin // TODO: move ops end
	 
	 end
	 
    AND, OR, XOR, NOT:                                                 begin // TODO: logical ops end
	 
	 end
	 
    LSH, LSHI, RSH, RSHI, ARSH, ARSHI:                                  begin // TODO: shift ops end
	 
	 end
	 
    WAIT:                                                              begin // TODO: wait / stall end
	 
	 end
    default: begin

    end

endcase
end 
endmodule
