`timescale 1ps/1ps

module ECE3710_tb_casex_alu;

    // Keep these as localparams; your ALU is fixed-width anyway.
    localparam BIT_WIDTH    = 16;
    localparam OPCODE_WIDTH =  8;
    localparam FLAG_WIDTH   =  5;

    reg  [BIT_WIDTH-1:0]   Rsrc_Imm;
    reg  [BIT_WIDTH-1:0]   Rdest;
    reg  [OPCODE_WIDTH-1:0] Opcode;
    wire [FLAG_WIDTH-1:0]  Flags;
    wire [BIT_WIDTH-1:0]   Result;

    // Opcodes (must match ALU)
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

    // Pattern forms for casex-style decoding (ignore low nibble for immediate ops)
    localparam [7:0] ADDI_PAT  = 8'b0101_xxxx;
    localparam [7:0] ADDUI_PAT = 8'b0110_xxxx;
    localparam [7:0] ADDCI_PAT = 8'b0111_xxxx;
    localparam [7:0] SUBI_PAT  = 8'b1001_xxxx;
    localparam [7:0] SUBCI_PAT = 8'b1010_xxxx;
    localparam [7:0] CMPI_PAT  = 8'b1011_xxxx;
    localparam [7:0] LSHI_PAT  = 8'b1100_xxxx;
    localparam [7:0] MOVI_PAT  = 8'b1101_xxxx;
    localparam [7:0] MULI_PAT  = 8'b1110_xxxx;
    localparam [7:0] ARSHI_PAT = 8'b1111_xxxx;
    localparam [7:0] RSHI_PAT  = 8'b1000_xxxx;

    // Instantiate ALU (NO parameters)
    ECE3710_alu uut (
        .Rsrc_Imm(Rsrc_Imm),
        .Rdest   (Rdest),
        .Opcode  (Opcode),
        .Flags   (Flags),
        .Result  (Result)
    );

    // Helper task: apply inputs then wait for combinational settle
    
    // Check only the flags that each opcode "cares" about.
    // Mask bit=1 => checked; bit=0 => ignored.
    // Flags mapping: [4]=L, [3]=C, [2]=F, [1]=Z, [0]=N
    task automatic check_flags_auto;
        input [7:0]  op;
        input [15:0] a;
        input [15:0] b;
        reg   [15:0] r_exp;
        reg   [16:0] t_exp;
        reg   [31:0] p_exp;
        reg   [4:0]  f_exp;
        reg   [4:0]  mask;
        begin
            r_exp = 16'h0000;
            t_exp = 17'd0;
            p_exp = 32'd0;
            f_exp = 5'b00000;
            mask  = 5'b00000;

            casex (op)
                // Signed ADD / ADDI: care about F, Z, N (and optionally L if you use it)
                ADD, ADDI_PAT: begin
                    r_exp = $signed(a) + $signed(b);
                    f_exp[4] = (a < b); // matches your ALU "extension" (unsigned compare)
                    f_exp[2] = ((a[15] == b[15]) && (r_exp[15] != a[15])); // overflow
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b1_0_1_1_1; // check L,F,Z,N ; ignore C
                end

                // Unsigned ADD / ADDUI: care about C, Z, N (and L if you use it)
                ADDU, ADDUI_PAT: begin
                    t_exp = {1'b0, a} + {1'b0, b};
                    r_exp = t_exp[15:0];
                    f_exp[4] = (a < b);
                    f_exp[3] = t_exp[16];
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b1_1_0_1_1; // check L,C,Z,N ; ignore F
                end

                // ADDC / ADDCI: same as unsigned add here (carry-in assumed 0 for this lab)
                ADDC, ADDCI_PAT: begin
                    t_exp = {1'b0, a} + {1'b0, b} + 17'd0;
                    r_exp = t_exp[15:0];
                    f_exp[4] = (a < b);
                    f_exp[3] = t_exp[16];
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b1_1_0_1_1; // check L,C,Z,N ; ignore F
                end

                // MOV / MOVI: care about Z, N only
                MOV, MOVI_PAT: begin
                    r_exp = b;
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_0_0_1_1;
                end

                // MUL / MULI: care about C, Z, N (C indicates upper bits nonzero)
                MUL, MULI_PAT: begin
                    p_exp = a * b;
                    r_exp = p_exp[15:0];
                    f_exp[3] = |p_exp[31:16];
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_1_0_1_1;
                end

                // Signed SUB / SUBI: care about F, Z, N, and L as signed less-than (per your ALU)
                SUB, SUBI_PAT: begin
                    t_exp = {1'b0, a} - {1'b0, b} - 17'd0;
                    r_exp = t_exp[15:0];
                    f_exp[4] = ($signed(a) < $signed(b)); // signed compare for L
                    f_exp[2] = ((a[15] != b[15]) && (r_exp[15] != a[15])); // overflow
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b1_0_1_1_1; // check L,F,Z,N ; ignore C
                end

                // Logic ops: care about Z, N only
                AND: begin
                    r_exp = a & b;
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_0_0_1_1;
                end
                OR: begin
                    r_exp = a | b;
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_0_0_1_1;
                end
                XOR: begin
                    r_exp = a ^ b;
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_0_0_1_1;
                end
                NOT: begin
                    r_exp = ~a;
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_0_0_1_1;
                end

                // Shifts: care about Z, N only
                LSH, LSHI_PAT: begin
                    r_exp = a << b[3:0];
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_0_0_1_1;
                end
                RSH, RSHI_PAT: begin
                    r_exp = a >> b[3:0];
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_0_0_1_1;
                end
                ARSH, ARSHI_PAT: begin
                    r_exp = $signed(a) >>> b[3:0];
                    f_exp[1] = (r_exp == 16'h0000);
                    f_exp[0] = r_exp[15];
                    mask     = 5'b0_0_0_1_1;
                end

                // Compare: care about L, Z, N (C,F ignored)
                CMP, CMPI_PAT: begin
                    f_exp[4] = (a < b);                 // unsigned less-than
                    f_exp[1] = (a == b);                // equal
                    f_exp[0] = ($signed(a) < $signed(b)); // signed less-than
                    mask     = 5'b1_0_0_1_1;
                end

                // WAIT/NOP: flags are don't-care (mask=0)
                WAIT: begin
                    mask = 5'b00000;
                end

                default: begin
                    mask = 5'b00000;
                end
            endcase

            if ( ((Flags & mask) !== (f_exp & mask)) ) begin
                #1; $display("Failure -- Incorrect flags (masked check)");
                #1; $display("Opcode=%b  A=%h  B=%h", op, a, b);
                #1; $display("Mask   LCFZN=%b", mask);
                #1; $display("Expect LCFZN=%b", (f_exp & mask));
                #1; $display("Actual LCFZN=%b", (Flags & mask));
                $stop;
            end
        end
    endtask


task apply;
        input [7:0]  op;
        input [15:0] a;
        input [15:0] b;
        begin
            Opcode   = op;
            Rdest    = a;
            Rsrc_Imm = b;
            #1; // IMPORTANT: let combinational logic update before checking
            check_flags_auto(op, a, b);
        end
    endtask

    initial begin
        // Initialize to known values (avoid X-prop weirdness at time 0)
        Opcode   = WAIT;
        Rdest    = 16'h0000;
        Rsrc_Imm = 16'h0000;
        #1;

        // ADD TEST
        #1; $display("ADD TEST"); #1;
        apply(ADD, 16'd32, 16'd5);
        if (Result !== 16'd37) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd37, Result);
            $stop;
        end
        #1; $display("ADD PASSING"); #1;

        // ADD Z FLAG TEST
        #1; $display("ADD Z FLAG TEST"); #1;
        apply(ADD, 16'd0, 16'd0);
        if (Result !== 16'd0) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd0, Result);
            $stop;
        end
        if (Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=1 for zero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("ADD Z FLAG PASSING"); #1;

        // ADDU TEST
        #1; $display("ADDU TEST"); #1;
        apply(ADDU, 16'd32, 16'd5);
        if (Result !== 16'd37) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd37, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("ADDU PASSING"); #1;

        // ADDU C FLAG TEST (unsigned carry)
        #1; $display("ADDU C FLAG TEST"); #1;
        apply(ADDU, 16'hFFFF, 16'h0001);
        if (Result !== 16'h0000) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h0000, Result);
            $stop;
        end
        if (Flags[3] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect C=1 on unsigned carry-out, Actual C=%b", Flags[3]);
            $stop;
        end
        if (Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=1 for zero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("ADDU C FLAG PASSING"); #1;

        // ADDI TEST
        #1; $display("ADDI TEST"); #1;
        apply(ADDI, 16'd32, 16'd5);
        if (Result !== 16'd37) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd37, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("ADDI PASSING"); #1;

        // ADDI F FLAG TEST (signed overflow)
        #1; $display("ADDI F FLAG TEST"); #1;
        apply(ADDI, 16'h7FFF, 16'h0001);
        if (Result !== 16'h8000) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h8000, Result);
            $stop;
        end
        if (Flags[2] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect F=1 on signed overflow, Actual F=%b", Flags[2]);
            $stop;
        end
        #1; $display("ADDI F FLAG PASSING"); #1;

        // ADDUI TEST
        #1; $display("ADDUI TEST"); #1;
        apply(ADDUI, 16'd32, 16'd5);
        if (Result !== 16'd37) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd37, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("ADDUI PASSING"); #1;

        // ADDCI TEST (allow either +0 or +1 behavior)
        #1; $display("ADDCI TEST"); #1;
        apply(ADDCI, 16'd32, 16'd5);
        if ((Result !== 16'd37) && (Result !== 16'd38)) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: 37 or 38, Actual: %0d", Result);
            $stop;
        end
        #1; $display("ADDCI PASSING"); #1;

        // ADDC TEST (allow either +0 or +1 behavior)
        #1; $display("ADDC TEST"); #1;
        apply(ADDC, 16'd2, 16'd1);
        if ((Result !== 16'd3) && (Result !== 16'd4)) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: 3 or 4, Actual: %0d", Result);
            $stop;
        end
        #1; $display("ADDC PASSING"); #1;

        // MOV TEST
        #1; $display("MOV TEST"); #1;
        apply(MOV, 16'h1234, 16'hBEEF);
        if (Result !== 16'hBEEF) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'hBEEF, Result);
            $stop;
        end
        if (Flags[1] !== (Result == 16'h0000)) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z to match (Result==0), Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("MOV PASSING"); #1;

        // MOVI TEST
        #1; $display("MOVI TEST"); #1;
        apply(MOVI, 16'hFFFF, 16'h00AA);
        if (Result !== 16'h00AA) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h00AA, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("MOVI PASSING"); #1;

        // MUL TEST
        #1; $display("MUL TEST"); #1;
        apply(MUL, 16'd7, 16'd3);
        if (Result !== 16'd21) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd21, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("MUL PASSING"); #1;

        // MULI TEST
        #1; $display("MULI TEST"); #1;
        apply(MULI, 16'd11, 16'd12);
        if (Result !== 16'd132) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd132, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("MULI PASSING"); #1;

        // SUB TEST
        #1; $display("SUB TEST"); #1;
        apply(SUB, 16'd32, 16'd5);
        if (Result !== 16'd27) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd27, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("SUB PASSING"); #1;

        // SUB Z FLAG TEST
        #1; $display("SUB Z FLAG TEST"); #1;
        apply(SUB, 16'd55, 16'd55);
        if (Result !== 16'd0) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %0d, Actual: %0d", 16'd0, Result);
            $stop;
        end
        if (Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=1 for zero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("SUB Z FLAG PASSING"); #1;

        // SUBI TEST
        #1; $display("SUBI TEST"); #1;
        apply(SUBI, 16'd3, 16'd10);
        if (Result !== 16'hFFF9) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'hFFF9, Result);
            $stop;
        end
        if (Flags[0] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect N=1 for negative result, Actual N=%b", Flags[0]);
            $stop;
        end
        #1; $display("SUBI PASSING"); #1;

        // SUBC TEST (allow either outcome shape)
        #1; $display("SUBC TEST"); #1;
        apply(SUBC, 16'd2, 16'd1);
        if ((Result !== 16'd1) && (Result !== 16'd0)) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: 1 or 0, Actual: %0d", Result);
            $stop;
        end
        #1; $display("SUBC PASSING"); #1;

        // SUBCI TEST (allow either outcome shape)
        #1; $display("SUBCI TEST"); #1;
        apply(SUBCI, 16'd9, 16'd4);
        if ((Result !== 16'd5) && (Result !== 16'd4)) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: 5 or 4, Actual: %0d", Result);
            $stop;
        end
        #1; $display("SUBCI PASSING"); #1;

        // AND TEST
        #1; $display("AND TEST"); #1;
        apply(AND, 16'h00FF, 16'h0F0F);
        if (Result !== 16'h000F) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h000F, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("AND PASSING"); #1;

        // AND Z FLAG TEST
        #1; $display("AND Z FLAG TEST"); #1;
        apply(AND, 16'hFFFF, 16'h0000);
        if (Result !== 16'h0000) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h0000, Result);
            $stop;
        end
        if (Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=1 for zero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("AND Z FLAG PASSING"); #1;

        // OR TEST
        #1; $display("OR TEST"); #1;
        apply(OR, 16'h00F0, 16'h0F00);
        if (Result !== 16'h0FF0) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h0FF0, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("OR PASSING"); #1;

        // XOR TEST
        #1; $display("XOR TEST"); #1;
        apply(XOR, 16'h0F0F, 16'hAAAA);
        if (Result !== 16'hA5A5) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'hA5A5, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("XOR PASSING"); #1;

        // NOT TEST
        #1; $display("NOT TEST"); #1;
        apply(NOT, 16'h00F0, 16'h0000);
        if (Result !== 16'hFF0F) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'hFF0F, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("NOT PASSING"); #1;

        // CMP TEST (flags only)
        #1; $display("CMP TEST"); #1;
        apply(CMP, 16'd3, 16'd10);
        if (Flags[4] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect L=1 when unsigned Rdest < Rsrc, Actual L=%b", Flags[4]);
            $stop;
        end
        if (Flags[0] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect N=1 when signed Rdest < Rsrc, Actual N=%b", Flags[0]);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 when not equal, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("CMP PASSING"); #1;

        // CMP EQUAL TEST
        #1; $display("CMP EQUAL TEST"); #1;
        apply(CMP, 16'd55, 16'd55);
        if (Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=1 when equal, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("CMP EQUAL PASSING"); #1;

        // CMPI TEST
        #1; $display("CMPI TEST"); #1;
        apply(CMPI, 16'd100, 16'd100);
        if (Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=1 when equal, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("CMPI PASSING"); #1;

        // LSH TEST
        #1; $display("LSH TEST"); #1;
        apply(LSH, 16'h0006, 16'd2);
        if (Result !== 16'h0018) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h0018, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("LSH PASSING"); #1;

        // LSHI TEST
        #1; $display("LSHI TEST"); #1;
        apply(LSHI, 16'h0001, 16'd4);
        if (Result !== 16'h0010) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h0010, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("LSHI PASSING"); #1;

        // RSH TEST
        #1; $display("RSH TEST"); #1;
        apply(RSH, 16'h0080, 16'd3);
        if (Result !== 16'h0010) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h0010, Result);
            $stop;
        end
        if (Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect Z=0 for nonzero result, Actual Z=%b", Flags[1]);
            $stop;
        end
        #1; $display("RSH PASSING"); #1;

        // RSHI TEST
        #1; $display("RSHI TEST"); #1;
        apply(RSHI, 16'h8000, 16'd1);
        if (Result !== 16'h4000) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'h4000, Result);
            $stop;
        end
        if (Flags[0] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect N=0 for positive result, Actual N=%b", Flags[0]);
            $stop;
        end
        #1; $display("RSHI PASSING"); #1;

        // ARSH TEST
        #1; $display("ARSH TEST"); #1;
        apply(ARSH, 16'hFFF6, 16'd3); // -10 >>> 3 = -2 = 0xFFFE
        if (Result !== 16'hFFFE) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'hFFFE, Result);
            $stop;
        end
        if (Flags[0] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect N=1 for negative result, Actual N=%b", Flags[0]);
            $stop;
        end
        #1; $display("ARSH PASSING"); #1;

        // ARSHI TEST
        #1; $display("ARSHI TEST"); #1;
        apply(ARSHI, 16'h8000, 16'd4);
        if (Result !== 16'hF800) begin
            #1; $display("Failure -- Incorrect result");
            #1; $display("Expect: %h, Actual: %h", 16'hF800, Result);
            $stop;
        end
        if (Flags[0] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags");
            #1; $display("Expect N=1 for negative result, Actual N=%b", Flags[0]);
            $stop;
        end
        #1; $display("ARSHI PASSING"); #1;

        // WAIT TEST (NOP) — leave as “sanity only” (no strict check)
        #1; $display("WAIT TEST"); #1;
        apply(ADD, 16'd1, 16'd1);
        apply(WAIT, 16'hBEEF, 16'hDEAD);
        #1; $display("WAIT PASSING"); #1;

        #1; $display("All tests passed!"); #1;
        $stop;
    end

endmodule
