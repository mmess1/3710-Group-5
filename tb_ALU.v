`timescale 1ps/1ps

module tb_ALU;
    parameter BIT_WIDTH    = 16;
    parameter OPCODE_WIDTH =  8;
    parameter FLAG_WIDTH   =  5;

    reg  [BIT_WIDTH-1:0]  Rsrc_Imm;
    reg  [BIT_WIDTH-1:0]     Rdest;
    reg  [OPCODE_WIDTH-1:0] Opcode;
    wire [FLAG_WIDTH-1:0]    Flags;
    wire [BIT_WIDTH-1:0]    Result; 

    localparam ADD   = 8'b0000_0101;
    localparam ADDI  = 8'b0101_xxxx;

    // You can use integers for exhaustive testing though you may have to use a bit mask since your data is 16-bits.
	 // Look into for-loops and $stop in Verilog if you want to create self-checking testbenches as I demonstrated -- 
	 // though that is notrequired. Also, don't forget to include just a bit of delay time (#1;) for a display.

    ALU #(.BIT_WIDTH(BIT_WIDTH),
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
        if(Result != 16'd37) begin
				#1; $display("Failure -- Incorrect result"); #1;
				#1; $display("Expect: %d, Actual: %d", Result, Rsrc_Imm + Rdest); #1;
				$stop; // This stops the sim so you can look at waveforms at the point of failure or continue the sim from this point.
		  end
        #1; $display("ADD PASSING"); #1; 
        
    end

endmodule
