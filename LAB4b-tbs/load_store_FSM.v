module load_store_FSM (
    
	input wire clk,
    input wire reset,     // active-low reset
    /* Reg file */
    input wire [15:0] wEnable,  // Control signal for register write enable
    /* ALU */
    input wire [7:0] opcode,  // The opcode (or instruction)
    input wire [4:0] Flags_in,  // Flags output (if needed for operations)
    /* RAM */
    output reg [15:0] ram_out,  // Instruction being processed
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
localparam [7:0] WAIT  = 8'h00,
                 ADD   = 8'h05, ADDU  = 8'h06, ADDC  = 8'h07,
                 ADDI  = 8'h50, ADDUI = 8'h60, ADDCI = 8'h70,
                 MOV   = 8'h0D, MOVI  = 8'hD0,
                 MUL   = 8'h0E, MULI  = 8'hE0,
                 SUB   = 8'h09, SUBC  = 8'h0A,
                 SUBI  = 8'h90, SUBCI = 8'hA0,
                 CMP   = 8'h0B, CMPI  = 8'hB0,
                 AND   = 8'h01, OR    = 8'h02, XOR   = 8'h03, NOT = 8'h04,
                 LSH   = 8'h0C, LSHI  = 8'hC0,
                 RSH   = 8'h08, RSHI  = 8'h80,
                 ARSH  = 8'h0F, ARSHI = 8'hF0;
				 LOAD  = 8'h40, // P-Code 4, Ext 0
                 STOR  = 8'h44; // P-Code 4, Ext 4
    wire decoded_Imm_sel;

// State encoding
localparam 	S0_FETCH   = 2'd0,
			S1_DECODE  = 2'd1;
			S2_EXECUTE = 2'd2;
			S3_STORE   = 2'd3;
			S4_LOAD    = 2'd4;
			S5_DOUT    = 2'd5;

    reg [2:0] PS, NS;  // Present state and next state
	 
	  // reg [15:0] local_instruction = 16'b0;

	// State register (use active-high reset)
	always @(posedge clk or posedge reset) begin
		if (reset)
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

        case (PS)
            S0_FETCH: begin
                // Fetch state: No operations, just fetch instruction
					 
            end

            S1_DECODE: begin			  	  
								end
							S2_EXECUTE: begin
								case(opcode)
									ADD, ADDU, ADDC, SUB, SUBI, SUBC, SUBCI, MUL, CMP: begin
										 wEnable = 16'b1; // Enable register write (assuming we write the result to a register)
										 pc_en = 1; // Enable PC increment (not a jump/branch)
									end
									
									// Immediate operations
									ADDI, ADDCI, ADDUI, SUBI, SUBCI, MULI, CMPI: begin
										 Imm_select = 1; // Use immediate for these operations
										 wEnable = 16'b1; // Enable register write (assuming destination register)
										 pc_en = 1; // PC should still increment normally
									end

									// Move operations
									MOV, MOVI: begin
										 if (instr_set == MOVI) begin
											  // MOVI: Immediate operation
											  Imm_select = 1; // Use immediate for MOVI
										 end else begin
											  // MOV: Register-to-register move
											  Imm_select = 0; // No immediate for MOV
						  
										 end

										 wEnable = 16'b1; // Enable register write (write to destination register)
										 pc_en = 1; // PC should increment normally
									end
									// Logical operations (AND, OR, XOR, NOT)
									AND, OR, XOR, NOT: begin
										 wEnable = 16'b1; // Enable register write
										 pc_en = 1; // PC increments normally
									end

									// Shift operations (LSH, LSHI, RSH, RSHI, ARSH, ARSHI)
									LSH, LSHI, RSH, RSHI, ARSH, ARSHI: begin
										 wEnable = 16'b1; // Enable register write
										 pc_en = 1; // PC should increment normally
									end

								 // decoder should be off--> must manually turn on PC and Write enable
								 pc_en = 1'b1;  // PC increments
								 wEnable = 16'b1;  // Enable write to register file
							end

								 lsc_mux_selct = 1'd1; // date from rdest addr

							/* Load/Store States */
					S3_STORE: begin
						 // 1) Enable the address input to the memory from the destination register (Rdst)
						 //    - The address for the store is typically the value from a base register (Rbase) + offset
						 //    - This address is used to access memory to write the data
						 //    - Enable memory address lines to send Rdst (or Rbase + offset) as the memory address

						lsc_mux_selct = 1'd1; // date from rdest addr
						
						 // 2) Enable the data input to memory from Port 1 (Port 1 contains data to be stored)
						 //    - Enable Port 1 for memory to store data that is in the register file
						 //    - Port 1 should receive data from the register that holds the value you want to store
						 //    - For example, Rsrc (source register) will have the data to write to memory
						 

						 // 3) Memory Write Enable Signal
						 //    - Enable memory write control signal (typically "mem_write") to indicate that memory should be written
						 //    - Set the correct control signals for the memory operation (e.g., mem_write = 1)
						 
						  we_a = 1; // Enable RAM write
						  en_a = 1; // Enable RAM read
						  
						  ram_en = 1; // Enable RAM for the store operation
						  pc_en = 1; // PC should increment normally

							pc_en = 1; // PC should increment normally
							we_a = 1; // Enable RAM write
							en_a = 1; // Enable RAM read
							ram_en = 1; // Enable RAM for the store operation
							fsm_alu_mem_selct = 1'd1; // regfile gets its value form the ram not alu

					end


					S4_LOAD: begin
						 // 1) Enable the address input to memory from the base register (Rbase) + offset
						 //    - The address for the load is calculated by adding the value of Rbase and the offset
						 //    - Send this address to memory so that the correct memory location is accessed

						 // 2) Enable the read port of memory (Port 1) to fetch data
						 //    - Enable the memory read control signal (e.g., mem_read) to indicate that data should be read from memory
						 //    - Memory will output the data to Port 1, so enable the read operation for Port 1

						 // 3) Transfer the data from memory to the destination register (Rdst)
						 //    - Take the data from the memory read output (DOUT from memory) and pass it to the destination register
						 //    - Enable the write control signal to the register file so that the data can be written into the destination register
						wEnable = 16'b0; // Write to register file after loading data
						pc_en = 0; // PC should increment normally
						en_a = 1; // Enable RAM read
						ram_en = 1; // Enable RAM for the load operation

						 we_a = 1; // Enable RAM write
						 en_a = 1; // Enable RAM read
						 ram_en = 1; // Enable RAM for the store operation
						 fsm_alu_mem_selct = 1'd1; // regfile gets its value form the ram not alu
						 
					end


						S5_DOUT: begin
							 // 1) Enable the register file to write the data from memory to the destination register (Rdst)
							 //    - The data from the load operation (DOUT from memory) should be written to Rdst
							 //    - Enable the write-back signal for the register file to write the loaded data into the destination register
								
							wEnable = // saved rdest reg	
								
							 // 2) Set the control signal to write the data into the register file
							 //    - Enable the register file's write control signal (e.g., write_enable) for the destination register
							 //    - The data from memory (DOUT) should be routed into the destination register
							 
							 

							 // 3) Finalize the operation (clear any relevant flags if necessary)
							 //    - Optionally, after writing to the register file, you might want to clear any temporary flags
							 //    - Transition to the next state, signaling that the load/store operation has completed
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
