`timescale 1ps/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Aliou Tippett, Abdulrahman Almutairi, Megan Genetti, Mechal Alali
//
// Create Date:    01/7/2026
// Design Name:
// Module Name:    ALU3710
// Project Name:   Lab assignment 1: Design of the ALU.
// Target Devices: FIX ME
// Description:    16-bit combinational ALU for CR16 baseline (+ extensions)
//                 FLAGS bit mapping (matches tb):
//                 Flags[4]=L, Flags[3]=C, Flags[2]=F, Flags[1]=Z, Flags[0]=N
//////////////////////////////////////////////////////////////////////////////////

module alu(
    input  wire [15:0] Rdest,     // input A
    input  wire [15:0] Rsrc_Imm,   // input B or immediate  (TB name)
    input  wire [7:0]  Opcode,
    output reg  [15:0] Result,
    output reg  [4:0]  Flags       // TB name
);

    // Opcodes (must match tb)
    localparam [7:0] ADD   = 8'b0000_0101;
    localparam [7:0] ADDU  = 8'b0000_0110;
    localparam [7:0] ADDC  = 8'b0000_0111;

    localparam [7:0] ADDI  = 8'b0101_0000;
    localparam [7:0] ADDUI = 8'b0110_0000;
    localparam [7:0] ADDCI = 8'b0111_0000;

    localparam [7:0] MOV   = 8'b0000_1101;
    localparam [7:0] MOVI  = 8'b1101_0000;

    localparam [7:0] MUL   = 8'b0000_1110;
    localparam [7:0] MULI  = 8'b1110_0000;

    localparam [7:0] SUB   = 8'b0000_1001;
    localparam [7:0] SUBI  = 8'b1001_0000;

    localparam [7:0] CMP   = 8'b0000_1011;
    localparam [7:0] CMPI  = 8'b1011_0000;

    localparam [7:0] AND   = 8'b0000_0001;
    localparam [7:0] OR    = 8'b0000_0010;
    localparam [7:0] XOR   = 8'b0000_0011;
    localparam [7:0] NOT   = 8'b0000_0100;

    localparam [7:0] LSH   = 8'b0000_1100;
    localparam [7:0] LSHI  = 8'b1100_0000;

    localparam [7:0] RSH   = 8'b0000_1000;
    localparam [7:0] RSHI  = 8'b1000_0000;

    localparam [7:0] ARSH  = 8'b0000_1111;
    localparam [7:0] ARSHI = 8'b1111_0000;

    localparam [7:0] WAIT  = 8'b0000_0000;

    reg  [16:0] tmp17;
    reg  [31:0] prod32;
    reg         carry_out;

    // Alias to keep your original variable naming style in the body
    wire [15:0] Rsrc = Rsrc_Imm;

    always @* begin
        // Safe defaults (prevents latching)
        Result = 16'h0000;
        Flags  = 5'b0_0_0_0_0;

        case (Opcode)

            // SIGNED ADD: set F overflow, C forced 0 per writeup note
            ADD, ADDI: begin
                Result = $signed(Rdest) + $signed(Rsrc);

                Flags[4] = (Rdest < Rsrc); // L (recommended extension)
                Flags[3] = 1'b0;           // C forced 0 for signed ops
                Flags[2] = ((Rdest[15] == Rsrc[15]) && (Result[15] != Rdest[15])); // F overflow
                Flags[1] = (Result == 16'h0000); // Z
                Flags[0] = Result[15];           // N
            end

            // UNSIGNED ADD: set C carry-out, F = 0
            ADDU, ADDUI: begin
                tmp17     = {1'b0, Rdest} + {1'b0, Rsrc};
                Result    = tmp17[15:0];
                carry_out = tmp17[16];

                Flags[4] = (Rdest < Rsrc);
                Flags[3] = carry_out;
                Flags[2] = 1'b0;
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            // ADD with carry (no carry-in available in this lab, use 0)
            ADDC, ADDCI: begin
                tmp17     = {1'b0, Rdest} + {1'b0, Rsrc} + 17'd0;
                Result    = tmp17[15:0];
                carry_out = tmp17[16];

                Flags[4] = (Rdest < Rsrc);
                Flags[3] = carry_out;
                Flags[2] = 1'b0;
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            // MOV / MOVI
            MOV, MOVI: begin
                Result  = Rsrc;
                Flags[4] = 1'b0;
                Flags[3] = 1'b0;
                Flags[2] = 1'b0;
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            // MUL / MULI (lower 16 bits result)
            MUL, MULI: begin
                prod32 = Rdest * Rsrc;
                Result = prod32[15:0];

                Flags[4] = 1'b0;
                Flags[3] = |prod32[31:16];    // C = upper bits nonzero
                Flags[2] = 1'b0;
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            // SIGNED SUB: set F overflow, C forced 0 per writeup note
            SUB, SUBI: begin
                tmp17  = {1'b0, Rdest} - {1'b0, Rsrc} - 17'd0;
					 Result = tmp17[15:0];

                Flags[4] = (Rdest < Rsrc);
                Flags[3] = tmp17[16];
                Flags[2] = ((Rdest[15] != Rsrc[15]) && (Result[15] != Rdest[15])); // F overflow
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
					 
            end

            // SUBC / SUBCI: unsigned form (no borrow-in available; use 0)
            //SUBC, SUBCI: begin
                //tmp17  = {1'b0, Rdest} - {1'b0, Rsrc} - 17'd0;
                //Result = tmp17[15:0];

                //Flags[4] = (Rdest < Rsrc);
                //Flags[3] = tmp17[16];          // borrow-out (your original choice)
                //Flags[2] = 1'b0;
                //Flags[1] = (Result == 16'h0000);
                //Flags[0] = Result[15];
            //end

            // AND / OR / XOR / NOT
            AND: begin
                Result  = Rdest & Rsrc;
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            OR: begin
                Result  = Rdest | Rsrc;
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            XOR: begin
                Result  = Rdest ^ Rsrc;
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            NOT: begin
                Result  = ~Rdest;
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            // Shifts
            LSH, LSHI: begin
                Result  = Rdest << Rsrc[3:0];
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            RSH, RSHI: begin
                Result  = Rdest >> Rsrc[3:0];
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            ARSH, ARSHI: begin
                Result  = $signed(Rdest) >>> Rsrc[3:0];
                Flags[1] = (Result == 16'h0000);
                Flags[0] = Result[15];
            end

            // Compare (flags only; Result not used by ISA)
            CMP, CMPI: begin
                Result  = Rdest; // deterministic
                Flags[4] = (Rdest < Rsrc);                       // L unsigned less-than
                Flags[3] = 1'b0;
                Flags[2] = 1'b0;
                Flags[1] = (Rdest == Rsrc);                      // Z equal
                Flags[0] = ($signed(Rdest) < $signed(Rsrc));     // N signed less-than (per your TB)
            end

            // WAIT/NOP: combinational ALU can't "hold previous" without state.
            WAIT: begin
                Result = Rdest;
                Flags  = Flags; // harmless; effectively don't-care in comb logic
            end

            default: begin
                Result = 16'h0000;
                Flags  = 5'b00000;
            end
        endcase
    end
endmodule
