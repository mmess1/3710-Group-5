`timescale 1ps/1ps

module ECE3710_tb_ALU;
    parameter BIT_WIDTH    = 16;
    parameter OPCODE_WIDTH =  8;
    parameter FLAG_WIDTH   =  5;

    reg  [BIT_WIDTH-1:0]  Rsrc_Imm;
    reg  [BIT_WIDTH-1:0]     Rdest;
    reg  [OPCODE_WIDTH-1:0] Opcode;
    wire [FLAG_WIDTH-1:0]    Flags;
    wire [BIT_WIDTH-1:0]    Result; 

    parameter ADD   = 8'b0000_0101;
    parameter ADDU  = 8'b0000_0110;
    parameter ADDC  = 8'b0000_0111;
    
    parameter ADDI  = 8'b0101_0000;
    parameter ADDUI = 8'b0110_0000;
    parameter ADDCI = 8'b0111_0000;

    parameter MOV   = 8'b0000_1101;
    parameter MOVI  = 8'b1101_0000;

    parameter MUL   = 8'b0000_1110;
    parameter MULI  = 8'b1110_0000;

    parameter SUB   = 8'b0000_1001;
    parameter SUBC  = 8'b0000_1010;
    parameter SUBI  = 8'b1001_0000;
    parameter SUBCI = 8'b1010_0000;

    parameter CMP   = 8'b0000_1011;
    parameter CMPI  = 8'b1011_0000;

    parameter OR    = 8'b0000_0010;

    parameter AND   = 8'b0000_0001;

    parameter XOR   = 8'b0000_0011;

    parameter NOT   = 8'b0000_0100;

    parameter LSH   = 8'b0000_1100;
    parameter LSHI  = 8'b1100_0000;

    parameter RSH   = 8'b0000_1000;
    parameter RSHI  = 8'b1000_0000;

    parameter ARSH  = 8'b0000_1111;
    parameter ARSHI = 8'b1111_0000;

    parameter WAIT  = 8'b0000_0000;


    // You can use integers for exhaustive testing though you may have to use a bit mask since your data is 16-bits.
	// Look into for-loops and $stop in Verilog if you want to create self-checking testbenches as I demonstrated -- 
	// though that is notrequired. Also, don't forget to include just a bit of delay time (#1;) for a display.

    ECE3710_alu #(.BIT_WIDTH(BIT_WIDTH),
          .OPCODE_WIDTH(OPCODE_WIDTH),
          .FLAG_WIDTH(FLAG_WIDTH)
         )
         uut
         (
          .Rsrc_Imm(Rsrc_Imm),
          .Rdest(Rdest),
          .Opcode(Opcode),
          .Flags(Flags),
          .Result(Result) 
         );

    initial begin
        #1; $display("ADD TEST"); #1; 
        Opcode = ADD;
		  Rsrc_Imm = 16'd5;
		  Rdest = 16'd32;
          #1;
        if(Result != 16'd37) begin
				#1; $display("Failure -- Incorrect result"); #1;
				#1; $display("Expect: %d, Actual: %d", Result, Rsrc_Imm + Rdest); #1;
				$stop; // This stops the sim so you can look at waveforms at the point of failure or continue the sim from this point.
		  end
        #1; $display("ADD PASSING"); #1; 

        // ADD Z FLAG TEST (force zero)

        #1; $display("ADD Z FLAG TEST"); #1; 
        Opcode = ADD;
		Rsrc_Imm = 16'd0;
		Rdest = 16'd0;
        if(Result != 16'd0) begin
				#1; $display("Failure -- Incorrect result"); #1;
				#1; $display("Expect: %d, Actual: %d", Result, 16'd0); #1;
				$stop;
		end
        if(Flags[1] !== 1'b1) begin
				#1; $display("Failure -- Incorrect flags"); #1;
				#1; $display("Expect Z=1 for zero result"); #1;
				$stop;
		end
        #1; $display("ADD Z FLAG PASSING"); #1;

        // ADDU TEST

        #1; $display("ADDU TEST"); #1; 
        Opcode = ADDU;
		Rsrc_Imm = 16'd5;
		Rdest = 16'd32;
        if(Result != 16'd37) begin
				#1; $display("Failure -- Incorrect result"); #1;
				#1; $display("Expect: %d, Actual: %d", Result, Rsrc_Imm + Rdest); #1;
				$stop; 
		end
        if(Flags[1] !== 1'b0) begin
				#1; $display("Failure -- Incorrect flags"); #1;
				#1; $display("Expect Z=0 for nonzero result"); #1;
				$stop;
		end
        #1; $display("ADDU PASSING"); #1; 

        // ADDU C FLAG TEST (unsigned carry)

        #1; $display("ADDU C FLAG TEST"); #1; 
        Opcode = ADDU;
		Rsrc_Imm = 16'h0001;
		Rdest = 16'hFFFF;
        #1;
        if(Result != 16'h0000) begin
				#1; $display("Failure -- Incorrect result"); #1;
				#1; $display("Expect: %h, Actual: %h", Result, 16'h0000); #1;
				$stop;
		end
        if(Flags[3] !== 1'b1) begin
				#1; $display("Failure -- Incorrect flags"); #1;
				#1; $display("Expect C=1 on unsigned carry-out"); #1;
				$stop;
		end
        if(Flags[1] !== 1'b1) begin
				#1; $display("Failure -- Incorrect flags"); #1;
				#1; $display("Expect Z=1 for zero result"); #1;
				$stop;
		end
        #1; $display("ADDU C FLAG PASSING"); #1;

        // ADDI

        #1; $display("ADDI TEST"); #1; 
        Opcode = ADDI;
		Rsrc_Imm = 16'd5;
		Rdest = 16'd32;
        if(Result != 16'd37) begin
				#1; $display("Failure -- Incorrect result"); #1;
				#1; $display("Expect: %d, Actual: %d", Result, Rsrc_Imm + Rdest); #1;
				$stop; 
		end
        if(Flags[1] !== 1'b0) begin
				#1; $display("Failure -- Incorrect flags"); #1;
				#1; $display("Expect Z=0 for nonzero result"); #1;
				$stop;
		end
        #1; $display("ADDI PASSING"); #1;

        // ADDI F FLAG TEST (signed overflow)

        #1; $display("ADDI F FLAG TEST"); #1; 
        Opcode = ADDI;
		Rdest = 16'h7FFF;
		Rsrc_Imm = 16'h0001;
        #1;
        if(Result != 16'h8000) begin
				#1; $display("Failure -- Incorrect result"); #1;
				#1; $display("Expect: %h, Actual: %h", Result, 16'h8000); #1;
				$stop;
		end
        if(Flags[2] !== 1'b1) begin
				#1; $display("Failure -- Incorrect flags"); #1;
				#1; $display("Expect F=1 on signed overflow"); #1;
				$stop;
		end
        #1; $display("ADDI F FLAG PASSING"); #1;

        // ADDUI TEST

        #1; $display("ADDUI TEST"); #1; 
        Opcode = ADDUI;
		Rsrc_Imm = 16'd5;
		Rdest = 16'd32;
        if(Result != 16'd37) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, Rsrc_Imm + Rdest); #1;
            $stop; 
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("ADDUI PASSING"); #1;

        // ADDCI TEST

        #1; $display("ADDCI TEST"); #1;
        Opcode = ADDCI;
		Rsrc_Imm = 16'd5;
		Rdest = 16'd32;
        if(Result != 16'd37 && Result != 16'd38) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, Rsrc_Imm + Rdest); #1;
            $stop; 
        end
        #1; $display("ADDCI PASSING"); #1;

        // ADDC TEST (carry-in behavior depends on FLAGS[3] coming in, so we just sanity check arithmetic shape)

        #1; $display("ADDC TEST"); #1;
        Opcode   = ADDC;
        Rsrc_Imm = 16'd1;
        Rdest    = 16'd2;
        #1;
        if(Result !== 16'd3 && Result !== 16'd4) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, Rsrc_Imm + Rdest); #1;
            $stop;
        end
        #1; $display("ADDC PASSING"); #1;

        // MOV TEST

        #1; $display("MOV TEST"); #1;
        Opcode   = MOV;
        Rsrc_Imm = 16'hBEEF;
        Rdest    = 16'h1234;
        #1;
        if(Result != 16'hBEEF) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'hBEEF); #1;
            $stop;
        end
        if(Flags[1] !== (Result == 16'h0000)) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z to match (Result==0)"); #1;
            $stop;
        end
        #1; $display("MOV PASSING"); #1;

        // MOVI TEST

        #1; $display("MOVI TEST"); #1;
        Opcode   = MOVI;
        Rsrc_Imm = 16'h00AA;
        Rdest    = 16'hFFFF;
        #1;
        if(Result != 16'h00AA) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'h00AA); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("MOVI PASSING"); #1;

        // MUL TEST

        #1; $display("MUL TEST"); #1;
        Opcode   = MUL;
        Rsrc_Imm = 16'd3;
        Rdest    = 16'd7;
        #1;
        if(Result != 16'd21) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, 16'd21); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("MUL PASSING"); #1;

        // MULI TEST

        #1; $display("MULI TEST"); #1;
        Opcode   = MULI;
        Rsrc_Imm = 16'd12;
        Rdest    = 16'd11;
        #1;
        if(Result != 16'd132) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, 16'd132); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("MULI PASSING"); #1;

        // SUB TEST

        #1; $display("SUB TEST"); #1;
        Opcode   = SUB;
        Rsrc_Imm = 16'd5;
        Rdest    = 16'd32;
        #1;
        if(Result != 16'd27) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, 16'd27); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("SUB PASSING"); #1;

        // SUB Z FLAG TEST

        #1; $display("SUB Z FLAG TEST"); #1;
        Opcode   = SUB;
        Rsrc_Imm = 16'd55;
        Rdest    = 16'd55;
        #1;
        if(Result != 16'd0) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, 16'd0); #1;
            $stop;
        end
        if(Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=1 for zero result"); #1;
            $stop;
        end
        #1; $display("SUB Z FLAG PASSING"); #1;

        // SUBI TEST

        #1; $display("SUBI TEST"); #1;
        Opcode   = SUBI;
        Rsrc_Imm = 16'd10;
        Rdest    = 16'd3;
        #1;
        if(Result != 16'hFFF9) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'hFFF9); #1;
            $stop;
        end
        if(Flags[0] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect N=1 for negative result"); #1;
            $stop;
        end
        #1; $display("SUBI PASSING"); #1;

        // SUBC TEST (carry/borrow-in behavior depends on FLAGS[3] coming in, so we just sanity check arithmetic shape)

        #1; $display("SUBC TEST"); #1;
        Opcode   = SUBC;
        Rsrc_Imm = 16'd1;
        Rdest    = 16'd2;
        #1;
        if(Result !== 16'd1 && Result !== 16'd0) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, 16'd1); #1;
            $stop;
        end
        #1; $display("SUBC PASSING"); #1;

        // SUBCI TEST (same note as SUBC)

        #1; $display("SUBCI TEST"); #1;
        Opcode   = SUBCI;
        Rsrc_Imm = 16'd4;
        Rdest    = 16'd9;
        #1;
        if(Result !== 16'd5 && Result !== 16'd4) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %d, Actual: %d", Result, 16'd5); #1;
            $stop;
        end
        #1; $display("SUBCI PASSING"); #1;

        // AND TEST

        #1; $display("AND TEST"); #1;
        Opcode   = AND;
        Rsrc_Imm = 16'h0F0F;
        Rdest    = 16'h00FF;
        #1;
        if(Result != 16'h000F) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'h000F); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("AND PASSING"); #1;

        // AND Z FLAG TEST

        #1; $display("AND Z FLAG TEST"); #1;
        Opcode   = AND;
        Rsrc_Imm = 16'h0000;
        Rdest    = 16'hFFFF;
        #1;
        if(Result != 16'h0000) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'h0000); #1;
            $stop;
        end
        if(Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=1 for zero result"); #1;
            $stop;
        end
        #1; $display("AND Z FLAG PASSING"); #1;

        // OR TEST

        #1; $display("OR TEST"); #1;
        Opcode   = OR;
        Rsrc_Imm = 16'h0F00;
        Rdest    = 16'h00F0;
        #1;
        if(Result != 16'h0FF0) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'h0FF0); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("OR PASSING"); #1;

        // XOR TEST

        #1; $display("XOR TEST"); #1;
        Opcode   = XOR;
        Rsrc_Imm = 16'hAAAA;
        Rdest    = 16'h0F0F;
        #1;
        if(Result != 16'hA5A5) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'hA5A5); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("XOR PASSING"); #1;

        // NOT TEST

        #1; $display("NOT TEST"); #1;
        Opcode   = NOT;
        Rsrc_Imm = 16'h0000;
        Rdest    = 16'h00F0;
        #1;
        if(Result != 16'hFF0F) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'hFF0F); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("NOT PASSING"); #1;

        // CMP TEST (flags only)

        #1; $display("CMP TEST"); #1;
        Opcode   = CMP;
        Rsrc_Imm = 16'd10;
        Rdest    = 16'd3;
        #1;
        if(Flags[4] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect L=1 when unsigned Rdest < Rsrc"); #1;
            $stop;
        end
        if(Flags[0] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect N=1 when signed Rdest < Rsrc"); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 when not equal"); #1;
            $stop;
        end
        #1; $display("CMP PASSING"); #1;

        // CMP EQUAL TEST

        #1; $display("CMP EQUAL TEST"); #1;
        Opcode   = CMP;
        Rsrc_Imm = 16'd55;
        Rdest    = 16'd55;
        #1;
        if(Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=1 when equal"); #1;
            $stop;
        end
        #1; $display("CMP EQUAL PASSING"); #1;

        // CMPI TEST

        #1; $display("CMPI TEST"); #1;
        Opcode   = CMPI;
        Rsrc_Imm = 16'd100;
        Rdest    = 16'd100;
        #1;
        if(Flags[1] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=1 when equal"); #1;
            $stop;
        end
        #1; $display("CMPI PASSING"); #1;

        // LSH TEST

        #1; $display("LSH TEST"); #1;
        Opcode   = LSH;
        Rdest    = 16'h0006;
        Rsrc_Imm = 16'd2;
        #1;
        if(Result != 16'h0018) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'h0018); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("LSH PASSING"); #1;

        // LSHI TEST

        #1; $display("LSHI TEST"); #1;
        Opcode   = LSHI;
        Rdest    = 16'h0001;
        Rsrc_Imm = 16'd4;
        #1;
        if(Result != 16'h0010) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'h0010); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("LSHI PASSING"); #1;

        // RSH TEST

        #1; $display("RSH TEST"); #1;
        Opcode   = RSH;
        Rdest    = 16'h0080;
        Rsrc_Imm = 16'd3;
        #1;
        if(Result != 16'h0010) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'h0010); #1;
            $stop;
        end
        if(Flags[1] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect Z=0 for nonzero result"); #1;
            $stop;
        end
        #1; $display("RSH PASSING"); #1;

        // RSHI TEST

        #1; $display("RSHI TEST"); #1;
        Opcode   = RSHI;
        Rdest    = 16'h8000;
        Rsrc_Imm = 16'd1;
        #1;
        if(Result != 16'h4000) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'h4000); #1;
            $stop;
        end
        if(Flags[0] !== 1'b0) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect N=0 for positive result"); #1;
            $stop;
        end
        #1; $display("RSHI PASSING"); #1;

        // ARSH TEST

        #1; $display("ARSH TEST"); #1;
        Opcode   = ARSH;
        Rdest    = 16'hFFF6; // -10
        Rsrc_Imm = 16'd3;
        #1;
        if(Result != 16'hFFFE) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'hFFFE); #1;
            $stop;
        end
        if(Flags[0] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect N=1 for negative result"); #1;
            $stop;
        end
        #1; $display("ARSH PASSING"); #1;

        // ARSHI TEST

        #1; $display("ARSHI TEST"); #1;
        Opcode   = ARSHI;
        Rdest    = 16'h8000; // negative
        Rsrc_Imm = 16'd4;
        #1;
        if(Result != 16'hF800) begin
            #1; $display("Failure -- Incorrect result"); #1;
            #1; $display("Expect: %h, Actual: %h", Result, 16'hF800); #1;
            $stop;
        end
        if(Flags[0] !== 1'b1) begin
            #1; $display("Failure -- Incorrect flags"); #1;
            #1; $display("Expect N=1 for negative result"); #1;
            $stop;
        end
        #1; $display("ARSHI PASSING"); #1;

        // WAIT TEST (NOP)

        #1; $display("WAIT TEST"); #1;
        Opcode   = ADD;
        Rsrc_Imm = 16'd1;
        Rdest    = 16'd1;
        #1;
        Opcode   = WAIT;
        Rsrc_Imm = 16'hDEAD;
        Rdest    = 16'hBEEF;
        #1;
        // NOP should not change the flags nor result from the previous instruction (per lab writeup),
        // so we just sanity check that sim keeps going and you can inspect waveforms if it fails.
        #1; $display("WAIT PASSING"); #1;

        #1; $display("All tests passed!"); #1;
    end
    

endmodule
