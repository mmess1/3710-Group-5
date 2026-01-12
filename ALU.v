`timescale 1ps/1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:  Aliou Tippett, Abdulrahman Almutairi, Megan Genetti, Mechal Alali
//
// Create Date:    01/7/2026
// Design Name:
// Module Name:    ECE3710_alu
// Project Name:   Lab assignment 1: Design of the ALU.
// Target Devices: FIX ME
// Description:    16-bit combinational ALU for CR16 baseline (+ extensions)
//                 FLAGS bit mapping (matches tb):
//                 FLAGS[4]=L, FLAGS[3]=C, FLAGS[2]=F, FLAGS[1]=Z, FLAGS[0]=N
//////////////////////////////////////////////////////////////////////////////////

module ECE3710_alu(
    input  wire [15:0] Rdest,   // input A
    input  wire [15:0] Rsrc,     // input B or immediate
    input  wire [7:0]  Opcode,
    output reg  [15:0] Result,
    output reg  [4:0]  FLAGS
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
    localparam [7:0] SUBC  = 8'b0000_1010;
    localparam [7:0] SUBI  = 8'b1001_0000;
    localparam [7:0] SUBCI = 8'b1010_0000;

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

    always @* begin
        // Safe defaults (prevents latching)
        Result = 16'h0000;
        FLAGS  = 5'bx_xxxx;   // {L,C,F,Z,N} default don't-care unless set below

        case (Opcode)

            // -------------------------
            // SIGNED ADD (no U): set F overflow, C forced 0 per writeup note
            // -------------------------
            ADD, ADDI: begin
                Result = $signed(Rdest) + $signed(Rsrc);

                FLAGS[4] = (Rdest < Rsrc); // L (recommended extension)
                FLAGS[3] = 1'b0;           // C forced 0 for signed ops (per writeup note)
                FLAGS[2] = ((Rdest[15] == Rsrc[15]) && (Result[15] != Rdest[15])); // F overflow
                FLAGS[1] = (Result == 16'h0000); // Z
                FLAGS[0] = Result[15];           // N
            end

            // -------------------------
            // UNSIGNED ADD (U): set C carry-out, F = 0
            // -------------------------
            ADDU, ADDUI: begin
                tmp17     = {1'b0, Rdest} + {1'b0, Rsrc};
                Result    = tmp17[15:0];
                carry_out = tmp17[16];

                FLAGS[4] = (Rdest < Rsrc);     // L (recommended extension)
                FLAGS[3] = carry_out;          // C
                FLAGS[2] = 1'b0;               // F = 0 for unsigned add
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            // -------------------------
            // ADD with carry (no carry-in available in this ALU-alone lab)
            // TB allows either +0 or +1; we use carry-in = 0.
            // -------------------------
            ADDC, ADDCI: begin
                tmp17     = {1'b0, Rdest} + {1'b0, Rsrc} + 17'd0;
                Result    = tmp17[15:0];
                carry_out = tmp17[16];

                FLAGS[4] = (Rdest < Rsrc);
                FLAGS[3] = carry_out;
                FLAGS[2] = 1'b0;
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            // -------------------------
            // MOV / MOVI
            // -------------------------
            MOV, MOVI: begin
                Result  = Rsrc;
                FLAGS[4] = 1'bx;                 // L unused
                FLAGS[3] = 1'bx;                 // C unused
                FLAGS[2] = 1'bx;                 // F unused
                FLAGS[1] = (Result == 16'h0000); // Z
                FLAGS[0] = Result[15];           // N
            end

            // -------------------------
            // MUL / MULI (lower 16 bits result)
            // -------------------------
            MUL, MULI: begin
                prod32 = Rdest * Rsrc;
                Result = prod32[15:0];

                FLAGS[4] = 1'bx;              // L unused
                FLAGS[3] = |prod32[31:16];    // C as "upper bits nonzero"
                FLAGS[2] = 1'bx;              // F unused
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            // -------------------------
            // SIGNED SUB / SUBI: set F overflow, C forced 0 per writeup note
            // -------------------------
            SUB, SUBI: begin
                Result = $signed(Rdest) - $signed(Rsrc);

                FLAGS[4] = (Rdest < Rsrc); // L (recommended extension)
                FLAGS[3] = 1'b0;           // C forced 0 for signed ops (per writeup note)
                FLAGS[2] = ((Rdest[15] != Rsrc[15]) && (Result[15] != Rdest[15])); // F overflow
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            // -------------------------
            // SUBC / SUBCI: treat as unsigned borrow form (no borrow-in available; use 0)
            // TB allows either outcome in its "shape" checks.
            // -------------------------
            SUBC, SUBCI: begin
                tmp17  = {1'b0, Rdest} - {1'b0, Rsrc} - 17'd0;
                Result = tmp17[15:0];

                FLAGS[4] = (Rdest < Rsrc);
                FLAGS[3] = tmp17[16];          // C as borrow-out
                FLAGS[2] = 1'b0;               // F not used here
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            // -------------------------
            // AND / OR / XOR
            // -------------------------
            AND: begin
                Result  = Rdest & Rsrc;
                FLAGS[4] = 1'bx; FLAGS[3] = 1'bx; FLAGS[2] = 1'bx;
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            OR: begin
                Result  = Rdest | Rsrc;
                FLAGS[4] = 1'bx; FLAGS[3] = 1'bx; FLAGS[2] = 1'bx;
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            XOR: begin
                Result  = Rdest ^ Rsrc;
                FLAGS[4] = 1'bx; FLAGS[3] = 1'bx; FLAGS[2] = 1'bx;
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            // -------------------------
            // NOT
            // -------------------------
            NOT: begin
                Result  = ~Rdest;
                FLAGS[4] = 1'bx; FLAGS[3] = 1'bx; FLAGS[2] = 1'bx;
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            // -------------------------
            // Shifts
            // -------------------------
            LSH, LSHI: begin
                Result  = Rdest << Rsrc[3:0];
                FLAGS[4] = 1'bx; FLAGS[3] = 1'bx; FLAGS[2] = 1'bx;
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            RSH, RSHI: begin
                Result  = Rdest >> Rsrc[3:0];
                FLAGS[4] = 1'bx; FLAGS[3] = 1'bx; FLAGS[2] = 1'bx;
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            ARSH, ARSHI: begin
                Result  = $signed(Rdest) >>> Rsrc[3:0];
                FLAGS[4] = 1'bx; FLAGS[3] = 1'bx; FLAGS[2] = 1'bx;
                FLAGS[1] = (Result == 16'h0000);
                FLAGS[0] = Result[15];
            end

            // -------------------------
            // Compare (flags only; Result not used by ISA)
            // -------------------------
            CMP, CMPI: begin
                Result  = Rdest; // deterministic (no latch)
                FLAGS[4] = (Rdest < Rsrc);                 // L unsigned less-than
                FLAGS[3] = 1'bx;                           // C unused
                FLAGS[2] = 1'bx;                           // F unused
                FLAGS[1] = (Rdest == Rsrc);                // Z equal
                FLAGS[0] = ($signed(Rdest) < $signed(Rsrc)); // N signed less-than
            end

            // -------------------------
            // WAIT/NOP: decoder should ignore writing state; outputs can be don't-care/pass-through
            // -------------------------
            WAIT: begin
                Result = Rdest;
                FLAGS  = 5'bx_xxxx;
            end

            default: begin
                Result = 16'h0000;
                FLAGS  = 5'b00000;
            end
        endcase
    end
endmodule
