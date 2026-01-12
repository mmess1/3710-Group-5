//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  Aliou Tippett, FIX ME
// 
// Create Date:    01/7/2026
// Design Name: 
// Module Name:    alu 
// Project Name:  Lab assignment 1: Design of the ALU.
// Target Devices: FIX ME
// Description: FIX ME
//
// Dependencies: 
//
//////////////////////////////////////////////////////////////////////////////////

module ALU(
    input  wire [15:0] Rdest, // input A
    input  wire [15:0] Rsrc,   // input B, or imm
    input  wire [7:0] Opcode,   
    output reg  [15:0] Result,     // will be set to Rdst outside ALU
    output reg  [4:0] FLAGS         // 0000 --> {C, L, F, Z, N} --> { FLAGS[3], FLAGS[2], FLAGS[1], FLAGS[0] }
);

parameter [7:0] ADD =       8'bxxxx_0101;
parameter [7:0] ADDU =      8'bxxxx_0110;
parameter [7:0] ADDC =      8'bxxxx_0111;
parameter [15:0] ADDI =     4'b0101_xxxx;
parameter [15:0] ADDUI =    4'b0110_xxxx;
parameter [15:0] ADDCI =    4'b0111_xxxx;

parameter [15:0]  MOV =     8'bxxxx_1101;
parameter [15:0]  MOVI =    4'b1101_xxxx;

parameter [7:0] MUL =       8'bxxxx_1110;
parameter [15:0] MULI =     8'b1110_xxxx;

parameter [7:0] SUB =       8'bxxxx_1001;
parameter [15:0] SUBC =     8'bxxxx_1010;
parameter [15:0] SUBI =     8'b1001_xxxx;
parameter [15:0] SUBCI =    8'b1010_xxxx;

parameter [15:0] CMP =      8'bxxxx_1011;
parameter [15:0] CMPI =     8'b1011_xxxx;

parameter [7:0]  OR =       8'bxxxx_0010;

parameter [15:0]  AND =     8'bxxxx_0001;

parameter [15:0]  XOR =     8'bxxxx_0011;

parameter [7:0]  NOT =      8'bxxxx_0100;

parameter [7:0]  LSH =      8'bxxxx_1100;
parameter [15:0] LSHI =     8'b1100_xxxx;

parameter [7:0]  RSH =      8'bxxxx_1000;
parameter [15:0] RSHI =     8'b1000_xxxx;

parameter [7:0]  ARSH =     8'bxxxx_1111;
parameter [15:0] ARSHI =    8'b1111_xxxx;

parameter [7:0]  WAIT =     8'bxxxx_0000;  // Use WAIT opcode as NOP



always @(Rsrc, Rdest, Opcode)
begin

    Result = 16'b0000_0000_0000_0000; // clear the result
    
    /* =========================
        * ALU Status Flags
        *
        * C (Carry): Set to 1 by ADDU, ADDC, or SUBC if a carry out (for addition) 
        * or borrow (for subtraction) occurs. Cleared otherwise.
        *
        * L (Low): Set by comparison operations (CMP, CMPI). Set to 1 if Rdest < Rsrc when interpreted as UNSIGNED numbers.
        *
        * F (Overflow): Set by signed arithmetic operations (ADD, SUB, ADDI, SUBI) 
        *   if a signed overflow occurs. Cleared otherwise.
        *
        * Z (Zero): Set by any operation that produces a result of 0 (AND, OR, XOR, arithmetic operations, CMP). 
        *   Not limited to comparison operations.
        *
        * N (Negative): Set by comparison operations (CMP, CMPI). Set to 1 if Rdest < Rsrc when interpreted as SIGNED numbers.
        * =========================
    */

    // note all have the same oppcode: ADD, ADDU, OR, SUB, CMP, SUBC, AND, XOR, MOV
    // Flags = 0000 --> {C, L, F, Z, N}
    casex (Opcode)

        ADD, ADDU, ADDUI,ADDC, ADDI ADDCI: begin        // Result = Rsrc + Rdst/(imm) + carry?
            wire use_carry = (Opcode == ADDC) || (Opcode == ADDCI);   // include carry if needed
            wire is_signed = (Opcode == ADDU) || (Opcode == ADDUI);   // signed add

            // Compute result first --> incase carry is need (use old carry)
            if (is_signed) begin
                Result = $signed(Rdest) + $signed(Rsrc);
            end else begin
                Result = Rdest + Rsrc + (use_carry ? FLAGS[3] : 1'b0); // maybe add carry
            end

            // Set flags after computing Result
            FLAGS[3] = (Result < Rdest);    // C: carry (unsigned)
            FLAGS[2] = (~Rdest[15] & ~Rsrc[15] & Result[15]) |   // F: signed overflow
                       ( Rdest[15] &  Rsrc[15] & ~Result[15]);
            FLAGS[1] = (Result == 16'b0);   // Z: zero
            FLAGS[0] = Result[15];          // N: negative/sign bit
        end

        MUL, MULI: begin                        // Result = Rsrc * Rdst/(imm)

            logic [31:0] prod;              // cast to  a much bigger bit-width

            prod   = Rsrc * Rdest;          // multiply
            Result = prod[15:0];            // keep lower 16 bits

            FLAGS[4] = |prod[31:16];        // C: upper bits nonzero -> overflow/carry
            FLAGS[1] = (Result == 16'b0);   // Z: result is zero
            FLAGS[0] = Result[15];          // N: sign bit of result
        end

        SUB, SUBC, SUBI, SUBCI: begin           // Result = Rdst - Rsrc/(imm)
            logic [16:0] temp;  // cast to 17 bits to detect barrow
            wire use_carry = (Opcode == SUBC) || (Opcode == SUBCI); // only care for SUBC and SUBCI
            // NOTE since Result = Rdst - Rsrc --> only need to exted Rdst
            temp = {1'b0, Rdest} - Rsrc - (use_carry ? FLAGS[3] : 1'b0);           // extend 1 bit to detect borrow
            
            if (Opcode != MULI && Opcode != MUL) begin
                Result = temp[15:0];    // only write the lower 16 bits for non-multiply instructions
            end
            // NOTE: MUL and MULI onyl set flags and dont set result

            FLAGS[4] = temp[16];           // C: borrow occurred if high bit is 1
            FLAGS[1] = (Result == 16'b0);  // Z: zero flag
            FLAGS[0] = Result[15];         // N: negative/sign bit
        end 

        AND, OR, XOR: begin

            if (Opcode == AND) begin
                Result = Rdest & Rsrc;  // bitwise AND
            end else if (Opcode == OR) begin
                Result = Rdest | Rsrc;  // bitwise OR
            end else if (Opcode == XOR) begin
                Result = Rdest ^ Rsrc;  // bitwise XOR
            end

            // Set flags --> NOTE: overflow, carry, L not used
            FLAGS[1] = (Result == 16'b0);  // Z: zero flag
            FLAGS[0] = Result[15];         // N: negative/sign bit
        end

        CMP, CMPI: begin                       // Compare Rdest and Rsrc/(imm) --> set flags only
            FLAGS[4] = (Rdest < Rsrc);                 // L: unsigned less-than
            FLAGS[1] = (Rdest == Rsrc);                // Z: equal
            FLAGS[0] = ($signed(Rdest) < $signed(Rsrc)); // N: signed less-than
        end

        NOT: begin                              // Result = ~Rdest
            Result = ~Rdest;                    // bitwise NOT
            FLAGS[1] = (Result == 16'b0);       // Z: zero flag
            FLAGS[0] = Result[15];              // N: negative/sign bit
        end

        LSH, LSHI: begin                        // Result = Rdest << shift_amount
            Result = Rdest << Rsrc[3:0];        // logical shift left
            FLAGS[1] = (Result == 16'b0);       // Z: zero flag
            FLAGS[0] = Result[15];              // N: negative/sign bit
        end

        RSH, RSHI: begin                        // Result = Rdest >> shift_amount
            Result = Rdest >> Rsrc[3:0];        // logical shift right
            FLAGS[1] = (Result == 16'b0);       // Z: zero flag
            FLAGS[0] = Result[15];              // N: negative/sign bit
        end

        ARSH, ARSHI: begin                      // Result = arithmetic shift right
            Result = $signed(Rdest) >>> Rsrc[3:0]; // arithmetic shift right (sign-extend)
            FLAGS[1] = (Result == 16'b0);       // Z: zero flag
            FLAGS[0] = Result[15];              // N: negative/sign bit
        end

        WAIT: begin                             // NOP (use WAIT opcode in ISA)
            Result = Rdest;                     // do not modify destination
            // NOTE: NOP should not change flags
        end

        default: begin
            Result = 16'b0;                 // safty clear result
            FLAGS  = 5'b00000;             // Safty clear all flags
        end
    endcase
end
endmodule
