module decoder(
    input wire [15:0] instr_set,

    output reg [15:0] Imm_in,
    output reg [7:0] opcode,
    output reg [3:0] Rdest, Rsrc,
);

// Decode instruction fields
opcode <= {instr_set[15:12], instr_set[7:4]};   // opcode (4 bits)
Rsrc <= instr_set[3:0];   // lower 4 bits of the immediate
Rdest <= instr_set[7:4];  // upper 4 bits of the immediate
Imm_in <= {instr_set[7:4], instr_set[3:0]}; // full 16-bit immediate value

endmodule