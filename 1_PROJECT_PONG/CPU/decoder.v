module decoder(
    input  wire [15:0] instr_set,

    output wire [15:0] Imm_in,
    output wire [7:0]  opcode,
    output wire [3:0]  Rdest,
    output wire [3:0]  Rsrc
);

    // opcode = {P-code, Ext}
    assign opcode = {instr_set[15:12], instr_set[7:4]};

    // Register fields
    assign Rdest  = instr_set[11:8];
    assign Rsrc   = instr_set[3:0];

    // Immediate (sign-extended imm8)
    assign Imm_in = {{8{instr_set[7]}}, instr_set[7:0]};

endmodule
