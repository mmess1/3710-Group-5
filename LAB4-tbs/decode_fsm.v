module decode_fsm (
    input  wire        clk,
    input  wire        reset,     // active-low reset

    // instruction set coming from hard-coded values in top-level module
    input  wire [15:0] instr_set,

    // FSM outputs (match slide names)
   output reg         pc_en,       // PC enable
   output reg         w_en,         // write enable
   output reg  [3:0]  rsrc,        // source register
   output reg  [3:0]  rdest,       // destination register
   output reg  [7:0]  opcode,      // opcode
   output reg         imm_sel,     // Immediate select (R/I type)
	output reg [15:0]	 imm16		  // 16-bit extended immediate
);

    // state encoding
    localparam S0_FETCH   = 2'd0;
    localparam S1_DECODE  = 2'd1;
    localparam S2_EXECUTE = 2'd2;

    reg [1:0] PS, NS;

    // State register
    always @(posedge clk or negedge reset) begin
        if (!reset) 
            PS <= S0_FETCH;
		  else
            PS <= NS;
    end

    // Next-state logic
    always @(*) begin
        NS = PS;
        case (PS)
            S0_FETCH:   NS = S1_DECODE;    // Move to decode state
            S1_DECODE: 	NS = S2_EXECUTE;  // Move to execute state
            S2_EXECUTE: NS = S0_FETCH;    // Back to fetch state
            default:    NS = S0_FETCH;
        endcase
    end

	 always @(*) begin
		pc_en = 1'b0;
		w_en  = 1'b0;

		case (PS)
			S2_EXECUTE: begin
				 pc_en = 1'b1;
				 w_en  = 1'b1;
			end
			default: begin
				 pc_en = 1'b0;
				 w_en  = 1'b0;
			end
		endcase
    end
	 
	 reg [15:0] instr_reg;
	 reg [3:0] Imm_low;   // lower 4 bits of the immediate
	 reg [3:0] Imm_high;  // upper 4 bits of the immediate

    // Output logic (based on FSM state)
    always @(posedge clk or negedge reset) begin
		if (!reset) begin  
			instr_reg      <= 16'd0;
			rsrc   		   <= 4'd0;
			rdest  		   <= 4'd0;
			opcode 		   <= 8'h00;
			imm_sel		   <= 1'b0;
			imm16  		   <= 16'd0;
		end else begin
        case (PS)
            S0_FETCH: begin
                // fetches the passed in instruction
					 instr_reg <= instr_set; 
            end

            S1_DECODE: begin
					// decode register locations
					rdest <= instr_reg[11:8];
					rsrc <= instr_reg[3:0];
                // Decode instruction fields
					Imm_low <= instr_reg[3:0];   // lower 4 bits of the immediate
					Imm_high <= instr_reg[7:4];  // upper 4 bits of the immediate
					
					// concatonate the upper and lower opcode bits
					opcode <= {instr_reg[15:12], instr_reg[7:4]};

					// Concatenate Imm_high and Imm_low to form a 16-bit immediate
					imm16 <= {{8{instr_reg[7]}}, instr_reg[7:4], instr_reg[3:0]};
	
					// if top bits of opcode are not 0, then it is an I-type instruction, otherwise
					// it is an R-type instruction
					imm_sel <= (instr_reg[15:12] != 4'b0000);
            end
        endcase
		end
  end
	 

endmodule