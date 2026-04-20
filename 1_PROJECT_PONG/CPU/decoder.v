module decoder(
    input  wire [15:0] instr_set,

    output wire [15:0] Imm_in,
    output wire [7:0]  opcode,
    output wire [3:0]  Rdest,
    output wire [3:0]  Rsrc
);

    wire [3:0] upper = instr_set[15:12];
    wire [3:0] ext   = instr_set[7:4];

    // opcode = {P-code, Ext} for register ops, {P-code, 0} for immediate ops
    // For register instructions (upper=0x0 or 0x4), use ext bits
    // For immediate instructions, ignore ext (it's part of immediate field)
    assign opcode = ((upper == 4'h0) || (upper == 4'h4)) ? {upper, ext} : {upper, 4'h0};

    // Register fields
    assign Rdest  = instr_set[11:8];
    assign Rsrc   = instr_set[3:0];

    // Immediate (sign-extended imm8)
    assign Imm_in = {{8{instr_set[7]}}, instr_set[7:0]};

endmodule
