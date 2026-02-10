module decoder(
    input wire [15:0] instr_set,
    input wire clk, reset, decoder_en,
    output reg [15:0] wEnable, Imm_in,
    output reg [7:0] opcode,
    output reg [3:0] Rdest, Rsrc_Imm,
	 output reg Imm_select
);

// Decode instruction fields
wire [3:0] op = instr_set[15:12];   // opcode (4 bits)
wire [3:0] code_ext = instr_set[7:4];  // extended code (4 bits)
wire [3:0] Imm_low = instr_set[3:0];   // lower 4 bits of the immediate
wire [3:0] Imm_high = instr_set[7:4];  // upper 4 bits of the immediate
wire [15:0] imm16;                     // full 16-bit immediate value

// Concatenate Imm_high and Imm_low to form a 16-bit immediate
assign imm16 = {{8{Imm_high[3]}}, Imm_high, Imm_low};

// Define the instruction set (localparams)
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


// load store;
localparam [15:0] LOAD 16'b0100_xxxx_0000_xxxx;
localparam [15:0] STOR 16'b0100_xxxx_0100_xxxx;

/*************************************************************************
                        Decoder Logic:
*************************************************************************/
always @(*) begin
    if (decoder_en != 0) begin
        // do nothing (or add any code if needed)
    end else begin
        // Default assignments
        opcode = instr_set[15:8];   // 8-bit opcode
        Rdest = instr_set[11:8];     // Destination register (4 bits)
        Rsrc_Imm = instr_set[3:0];  // Source register or Immediate (4 bits)
        Imm_select = 0;              // Default Imm_select
        
        // Decode instructions
        case (opcode)
            ADD, ADDU, ADDC, SUB, SUBI, SUBC, SUBCI, MUL, CMP: begin
                // Arithmetic operations (set up registers, flags, etc.)
                Imm_select = 0; // No immediate value for these ops
            end
            
            ADDI, ADDCI, ADDUI, SUBI, SUBCI, MULI, CMPI: begin
                // Immediate operations (set up register, immediate, etc.)
                Imm_select = 1; // Immediate value used
                Imm_in = imm16; // Pass the full 16-bit immediate
            end
            
            MOV, MOVI: begin
                // Move operations
                Imm_select = 1; // Use immediate for MOVI
                Imm_in = imm16; // Move the immediate value
            end
            
            AND, OR, XOR, NOT: begin
                // Logical operations (AND, OR, XOR, NOT)
                Imm_select = 0; // No immediate value for these ops
            end
            
            LSH, LSHI, RSH, RSHI, ARSH, ARSHI: begin
                // Shift operations
                Imm_select = 0; // Shifts don't use immediate values, just registers
            end
            
            WAIT: begin
                // Wait/idle operation
                Imm_select = 0; // No operation for WAIT
            end
            
            default: begin
                // Default case: handle unexpected instructions
                Imm_select = 0;
            end
        endcase
    end
end
endmodule