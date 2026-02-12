module decoder(
    input wire clk, reset, decoder_en,
    input wire [15:0] instr_set,

    /* REGFILE */
    output reg [15:0] wEnable,

    /* ALU / muxes */
    output reg [15:0] Imm_in,
    output reg [7:0] opcode,
    output reg [3:0] Rdest_select, Rsrc_select,
    output reg Imm_select,

    /* PC */
    output reg [15:0] pc_add_k,
    output reg pc_mux_selct, pc_en,

    /* RAM */
    output reg we_a, en_a, en_b, ram_en,

    /* LS_cntr MUX */
    output reg lsc_mux_selct
);

// Decode instruction fields
wire [3:0] op = instr_set[15:12];   // opcode (4 bits)
wire [3:0] code_ext = instr_set[7:4];  // extended code (4 bits)
wire [3:0] Imm_low = instr_set[3:0];   // lower 4 bits of the immediate
wire [3:0] Imm_high = instr_set[7:4];  // upper 4 bits of the immediate
wire [15:0] imm16 = {Imm_high, Imm_low}; // full 16-bit immediate value

// Instruction set (localparams)
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

// Load/Store
localparam [15:0] LOAD  = 16'b0100_xxxx_0000_xxxx;
localparam [15:0] STOR  = 16'b0100_xxxx_0100_xxxx;

/*************************************************************************
                        Decoder Logic:
*************************************************************************/
// should be Combinational

always @(posedge clk or posedge reset) begin
    if (reset or !decoder_en) begin
        // Reset default values
        wEnable = 16'b0;
        Imm_in = 16'b0;
        opcode = 8'b0;
        Rdest = 4'b0;
        Rsrc_Imm = 4'b0;
        Imm_select = 0;
        pc_add_k = 16'b0;
        pc_mux_selct = 0;
        pc_en = 0;
        we_a = 0;
        en_a = 0;
        en_b = 0;
        ram_en = 0;
        lsc_mux_selct = 0;
    end else if (decoder_en) begin
        // Decode instructions
		  fsm_alu_mem_selct = 1'd0; // always zero except for in load
		  /* these never change */
		   Rdest = instr_set[11:8]; // Destination register
         Rsrc_Imm = instr_set[7:4]; // Source register
		  
        case (opcode)
            // Arithmetic operations
            ADD, ADDU, ADDC, SUB, SUBI, SUBC, SUBCI, MUL, CMP: begin
                Imm_select = 0; // No immediate for these ops (register-based)
                wEnable = 16'b1; // Enable register write (assuming we write the result to a register)
                pc_en = 1; // Enable PC increment (not a jump/branch)
                pc_mux_selct = 0; // PC increments by 1
                we_a = 0; // Not a RAM write
                en_a = 0; // Not enabling any RAM ports
                en_b = 0; // Not enabling any RAM ports
                ram_en = 0; // RAM is not enabled
            end
            
            // Immediate operations
            ADDI, ADDCI, ADDUI, SUBI, SUBCI, MULI, CMPI: begin
                Imm_select = 1; // Use immediate for these operations
                Imm_in = imm16; // Pass the full 16-bit immediate
                wEnable = 16'b1; // Enable register write (assuming destination register)
                pc_en = 1; // PC should still increment normally
                pc_mux_selct = 0; // PC increments by 1
                we_a = 0; // Not a RAM write
                en_a = 0; // Not enabling any RAM ports
                en_b = 0; // Not enabling any RAM ports
                ram_en = 0; // RAM is not enabled
            end

				// Move operations
				MOV, MOVI: begin
					 if (instr_set == MOVI) begin
						  // MOVI: Immediate operation
						  Imm_select = 1; // Use immediate for MOVI
						  Imm_in = imm16; // Immediate value
					 end else begin
						  // MOV: Register-to-register move
						  Imm_select = 0; // No immediate for MOV
						  Imm_in = 16'b0; // No immediate value
					 end

					 wEnable = 16'b1; // Enable register write (write to destination register)
					 pc_en = 1; // PC should increment normally
					 pc_mux_selct = 0; // Normal PC increment
					 we_a = 0; // Not a RAM write
					 en_a = 0; // Not enabling any RAM ports
					 en_b = 0; // Not enabling any RAM ports
					 ram_en = 0; // RAM is not enabled
				end
            // Logical operations (AND, OR, XOR, NOT)
            AND, OR, XOR, NOT: begin
                Imm_select = 0; // No immediate for these ops
                wEnable = 16'b1; // Enable register write
                pc_en = 1; // PC increments normally
                pc_mux_selct = 0; // PC increments by 1
                we_a = 0; // Not a RAM write
                en_a = 0; // Not enabling any RAM ports
                en_b = 0; // Not enabling any RAM ports
                ram_en = 0; // RAM is not enabled
            end

            // Shift operations (LSH, LSHI, RSH, RSHI, ARSH, ARSHI)
            LSH, LSHI, RSH, RSHI, ARSH, ARSHI: begin
                Imm_select = 0; // Shift operations typically don’t use an immediate value
                wEnable = 16'b1; // Enable register write
                pc_en = 1; // PC should increment normally
                pc_mux_selct = 0; // PC increments by 1
                we_a = 0; // Not a RAM write
                en_a = 0; // Not enabling any RAM ports
                en_b = 0; // Not enabling any RAM ports
                ram_en = 0; // RAM is not enabled
            end

            // WAIT instruction (idle state)
            WAIT: begin
                Imm_select = 0; // No operation for WAIT
                wEnable = 16'b0; // No register write
                pc_en = 1; // Even though WAIT does nothing, we need to increment PC normally
                pc_mux_selct = 0; // Normal PC increment
                we_a = 0; // No RAM write
                en_a = 0; // No RAM enable
                en_b = 0; // No RAM enable
                ram_en = 0; // RAM is not enabled
            end

            // Load/Store operations (e.g., LOAD, STOR)
            LOAD: begin
                Imm_select = 0; // No immediate for LOAD (address comes from registers)
                wEnable = 16'b1; // Write to register file after loading data
                pc_en = 1; // PC should increment normally
                pc_mux_selct = 0; // PC increments by 1
                we_a = 0; // Not a RAM write
                en_a = 1; // Enable RAM read
                en_b = 0; // Not using another RAM port
                ram_en = 1; // Enable RAM for the load operation
            end

            STOR: begin
                Imm_select = 0; // No immediate for STORE
                wEnable = 0; // No register write
                pc_en = 1; // PC should increment normally
                pc_mux_selct = 0; // PC increments by 1
                we_a = 1; // Enable RAM write
                en_a = 1; // Enable RAM read
                en_b = 0; // Not using another RAM port
                ram_en = 1; // Enable RAM for the store operation
					 
					 fsm_alu_mem_selct = 1'd1; // regfile gets its value form the ram not alu
            end

            // Default case (if instruction doesn't match any of the patterns)
            default: begin
                Imm_select = 0;
                wEnable = 16'b0;
                pc_en = 1;
                pc_mux_selct = 0;
                we_a = 0;
                en_a = 0;
                en_b = 0;
                ram_en = 0;
            end
        endcase
    end
end
endmodule