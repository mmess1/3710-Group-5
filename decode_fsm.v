module decode_fsm (
    input  wire        clk,
    input  wire        reset,     // active-low reset

    // instruction set coming from hard-coded values in top-level module
    input  wire [15:0] instr_set,

    /* REG FILE */
   output reg         w_en,         // write enable
   output reg  [3:0]  rdest,       // destination register
   output reg  [7:0]  opcode,      // opcode
   output reg         imm_sel,      // Immediate select (R/I type)
	output reg  [3:0]  rsrc,        // source register
	
	/* MEMORY CONTROLS */
	
	// external from fsm
	output reg [15:0] inst_branch, 
	
	//extern -->fsm
	output reg [15:0]ram_out,
	
	// extern --> from fsm to ..
	output reg fsm_alu_mem_selct, 

	output reg load_en,

	output reg [15:0] instr_old, // buffed inst

		// external 
		wire [15:0]instr_new,
	
	
	/* PC CONTROLS */
	output reg  pc_en
	
);

    // state encoding
    localparam S0_FETCH   = 2'd0;
    localparam S1_DECODE  = 2'd1;
    localparam S2_EXECUTE = 2'd2;
	 
	 //laod /store
	 localparam S3_STORE  = 2'd3;
    localparam S4_LOAD = 2'd4;
    localparam S5_DOUT = 2'd5;
	 
	 
	 // LOAD STROE INCT
	 localparam [15:0] LOAD 16'b0100_xxxx_0000_xxxx;
	 localparam [15:0] STOR 16'b0100_xxxx_0100_xxxx;

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
            S0_FETCH:  NS = S1_DECODE;    // Move to decode state
            S1_DECODE: 	begin
				
				casex(instr_set)
					
					STOR: begin
						NS = S3_STORE;
					end
					LOAD: begin
							NS = S4_LOAD;
					end
					default begin
						NS = S2_EXECUTE;
					end
				end
				
				NS = S2_EXECUTE;  // Move to execute state
            S2_EXECUTE: NS = S0_FETCH;    // Back to fetch state
            
				
				/*LOAD/STORE STATES */
				S3_STORE:    NS = SO_FETCH;
				S4_LOAD:		NS = S5_DOUT
				S5_DOUT:    NS = S0_FETCH;
				default:    NS = S0_FETCH;	
        endcase
    end

    // Decoder Module Instantiation
   wire [15:0] wEnable;
   wire [15:0] Imm_in;
   wire [7:0]  decoded_opcode;
   wire [3:0]  decoded_Rdest, decoded_Rsrc_Imm;
	wire        decoded_Imm_sel;
  reg decoder_en;

    decoder u_decoder (
        .instr_set(instr_set),
        .clk(clk),
        .reset(reset),
        .wEnable(wEnable),
        .Imm_in(Imm_in),
        .opcode(decoded_opcode),
        .Rdest(decoded_Rdest),
        .Rsrc_Imm(decoded_Rsrc_Imm),
        .Imm_select(decoded_Imm_sel)
    );

    // Output logic (based on FSM state)
    always @(*) begin
        // Default values
		  
        pc_en   = 1'b0;
        w_en    = 1'b0;
        rsrc    = 4'b0000;
        rdest   = 4'b0000;
        opcode  = 8'h00;
        imm_sel = 1'b0;
		  decoder_en = 1'b0;

        case (PS)
            S0_FETCH: begin
                // Does nothing during fetch state
                pc_en   = 1'b0;
                w_en    = 1'b0;
            end

            S1_DECODE: begin
                // Decode instruction; `pc_en` and `w_en` stay low
                // `rsrc`, `rdest`, `opcode`, and `imm_sel` are set by the decoder
               
					 decoder_en = 1'b1;
					rsrc    = decoded_Rsrc_Imm;
                rdest   = decoded_Rdest;
                opcode  = decoded_opcode;
                imm_sel = decoded_Imm_sel;
            end

            S2_EXECUTE: begin
                // Execute state: Enable PC increment and writing to registers
                pc_en   = 1'b1;  // PC increments
                w_en    = 1'b1;  // Write to register file
            end

            default: begin
                // Default case (failsafe)
                pc_en   = 1'b0;
                w_en    = 1'b0;
                rsrc    = 4'b0000;
                rdest   = 4'b0000;
                opcode  = 8'h00;
                imm_sel = 1'b0;
            end
        endcase
    end

endmodule
