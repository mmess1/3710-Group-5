module load_store_FSM (
    
	 input wire clk,
    input wire reset,     // active-low reset
    /* Reg file */
    output reg [3:0] wEnable,  // Control signal for register write enable
    /* ALU */
    input wire [7:0] opcode,  // The opcode (or instruction)
    input wire [4:0] Flags_in,  // Flags output (if needed for operations)
    /* RAM */
    output reg [15:0] instr_set,  // Instruction being processed
    output reg we_a, en_a, en_b, ram_wen,
    /* LS_cntr MUX */
    output reg lsc_mux_selct,  // Load/Store counter MUX select
    /* PC */
    output reg [15:0] pc_add_k,  // Program counter address (for jumps or branches)
    output reg pc_mux_selct, pc_en,  // Control signals for the program counter
    /* MUXs */
    output reg fsm_alu_mem_selct,  // ALU/Memory select for MUX
    output reg [3:0] Rdest_select, Rsrc_select,  // Register destination and source select
    output reg [15:0] Imm_in,  // Immediate input
    output reg Imm_select,  // Select signal for immediate value
    output reg decoder_en   // Decoder enable signal
);

// Decoder Module Instantiation with all inputs connected
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

wire decoded_Imm_sel;

    // State encoding
    localparam S0_FETCH   = 2'd0;
    localparam S1_DECODE  = 2'd1;
    localparam S2_EXECUTE = 2'd2;
    localparam S3_STORE   = 2'd3;
    localparam S4_LOAD    = 2'd4;
    localparam S5_DOUT    = 2'd5;

    // LOAD/STORE instruction patterns
 localparam [15:0] LOAD  = 16'b0100_xxxx_0000_xxxx;
 localparam [15:0] STOR  = 16'b0100_xxxx_0100_xxxx;

    reg [1:0] PS, NS;  // Present state and next state
	 
	  // reg [15:0] local_instruction = 16'b0;

    // State register
    always @(posedge clk or negedge reset) begin
        if (!reset)
            PS <= S0_FETCH; // Default to fetch state on reset
        else
            PS <= NS;
    end

    // Next-state logic
    always @(*) begin
        NS = PS;
        case (PS)
            S0_FETCH:  NS = S1_DECODE;    // Move to decode state
            S1_DECODE: begin
                casex (instr_set)
                    STOR: NS = S3_STORE;
                    LOAD: NS = S4_LOAD;
                    default: NS = S2_EXECUTE;
                endcase
            end
            S2_EXECUTE: NS = S0_FETCH;    // Back to fetch state
            
            /* LOAD/STORE States */
            S3_STORE: NS = S0_FETCH; // Back to fetch after store
            S4_LOAD: NS = S5_DOUT; // After loading data, move to the data out state
            S5_DOUT: NS = S0_FETCH; // Back to fetch after data out (if needed)
            default: NS = S0_FETCH;  // Default state is fetch
        endcase
    end

 // Decoder instantiation with full set of inputs and outputs
 decoder u_decoder (
        .instr_set(instr_set),
        .clk(clk),
        .reset(reset),

        .Rdest_select(Rdest_select),
        .Rsrc_select(Rsrc_select),
		  .Imm_in(Imm_in),
        .opcode(opcode),
        .Imm_select(Imm_select)
 );
 
 reg load_en;
 reg [15:0] buff_instr;
 
 // inst Buffer
instr_buffer buff(
 .clk(clk),        
.reset(reset),    
.load_en(load_en),     
.in(instr_set),  
.out(buff_instr)
);

    // Output logic (based on FSM state)
    always @(*) begin
        // Default values
        
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

		  load_en = 0;
		  
        case (PS)
            S0_FETCH: begin
                // Fetch state: No operations, just fetch instruction
					 load_en = 1;
            end

            S1_DECODE: begin
									// Arithmetic operations

										  	  
								end

							S2_EXECUTE: begin
								 // decoder should be off--> must manually turn on PC and Write enable
								 
								 //
								 
								 
								 pc_en = 1'b1;  // PC increments
								 wEnable = Rdest_select;  // Enable write to register file
							end

							/* Load/Store States */
					S3_STORE: begin
						
				   lsc_mux_selct = 1'd1; // date from rdest addr	
				   pc_en = 1; // PC should increment normally
					we_a = 1; // Enable RAM write
					en_a = 1; // Enable RAM read
				   ram_en = 1; // Enable RAM for the store operation
				

					end


					S4_LOAD: begin
						 
						 lsc_mux_selct = 1'd1; // date from rdest addr
						 en_a = 1; // Enable RAM read
						 ram_en = 1; // Enable RAM for the store operation
						 fsm_alu_mem_selct = 1'd1; // regfile gets its value form the ram not alu
						 
					end


						S5_DOUT: begin
							wEnable <= buff_instr[7:4];  // upper 4 bits of the immediate
							fsm_alu_mem_selct = 1;
							pc_en = 1;			

						end

            default: begin
                // Default case (failsafe)
                pc_en = 1'b0;
                wEnable = 16'b0;
                Rsrc_select = 4'b0000;
                Rdest_select = 4'b0000;
                opcode = 8'h00;
                Imm_select = 1'b0;
            end
        endcase
    end

endmodule
