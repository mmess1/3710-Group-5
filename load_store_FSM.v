module load_store_FSM (
	 
	 input wire clk,
    input wire reset,     // active-low reset

    input  wire [15:0] instr_set,

    /* ALU */
    input  wire [4:0] Flags_in,

    /* Reg file */
    output reg  [15:0] wEnable,  // one-hot write enable

    /* Decoder outputs to datapath */
    output wire [7:0]  opcode,
    output wire [3:0]  Rdest_select,
    output wire [3:0]  Rsrc_select,
    output wire [7:0] Imm_in,
    output reg         Imm_select,

    /* RAM */
    output reg we_a, en_a, en_b, ram_wen,

    /* LS_cntr MUX */
    output reg lsc_mux_selct,

    /* PC */
    output reg [7:0] pc_add_k,
    output reg pc_mux_selct, pc_en,

    /* MUXs */
    output reg fsm_alu_mem_selct,

    output reg decoder_en   // Decoder enable signal
);

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
localparam [15:0] LSH   = 16'b1000_xxxx_1100_xxxx;
localparam [15:0] LSHI  = 16'b1000_xxxx_0000_xxxx;
localparam [15:0] RSH   = 16'b0000_xxxx_1000_xxxx;
localparam [15:0] RSHI  = 16'b1000_xxxx_xxxx_xxxx;
localparam [15:0] ARSH  = 16'b0000_xxxx_1111_xxxx;
localparam [15:0] ARSHI = 16'b1111_xxxx_xxxx_xxxx;
localparam [15:0] WAIT  = 16'b0000_xxxx_0000_xxxx;

localparam [15:0] BRANCH = 16'b1100_xxxx_xxxx_xxxx;

// branch coditions:
// Define 16 branch condition flags as localparams
// Define 16 branch condition flags as localparams
localparam [3:0] EQ  = 4'b0000;   // Equal (result == 0)
localparam [3:0] NE  = 4'b0001;   // Not Equal (result != 0)
localparam [3:0] GE  = 4'b1101;   // Greater Than or Equal (signed, result >= 0)
localparam [3:0] CS  = 4'b0010;   // Less Than (signed, result < 0)
localparam [3:0] CC  = 4'b0011;   // Greater Than (result > 0)
localparam [3:0] HI  = 4'b0100;   // Less Than or Equal (signed, result <= 0)
localparam [3:0] LS  = 4'b0101;   // Carry Set (carry flag = 1)
localparam [3:0] LO  = 4'b1010;   // Carry Clear (carry flag = 0)
localparam [3:0] HS  = 4'b1011;   // Overflow (overflow flag = 1)
localparam [3:0] GT  = 4'b0110;   // No Overflow (overflow flag = 0)
localparam [3:0] LE  = 4'b0111;   // Zero Set (Zero flag = 1)
localparam [3:0] FS  = 4'b1000;   // Not Zero (Zero flag = 0)
localparam [3:0] FC  = 4'b1001;   // Always (always true, unconditional)
localparam [3:0] LT  = 4'b1100;   // Higher (for unsigned comparison, result > 0)
localparam [3:0] UC  = 4'b1110;   // Lower or Same (for unsigned comparison, result <= 0)
localparam [3:0] XX  = 4'b1111;   // Minus (Negative result, sign bit = 1)


// LOAD/STORE instruction patterns
localparam [15:0] LOAD  = 16'b0100_????_0000_????;
localparam [15:0] STOR  = 16'b0100_????_0100_????;

    // State encoding
    localparam [2:0] S0_FETCH   = 3'd0;
    localparam [2:0] S1_DECODE  = 3'd1;
    localparam [2:0] S2_EXECUTE = 3'd2;
    localparam [2:0] S3_STORE   = 3'd3;
    localparam [2:0] S4_LOAD    = 3'd4;
    localparam [2:0] S5_DOUT    = 3'd5;
	 
	 localparam [2:0] S6_BRANCH  = 3'd6;

    reg [2:0] PS, NS;  // Present state and next state

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
            S0_FETCH:  NS = S1_DECODE;

            // different way (no is_store/is_load wires): just match instruction
            S1_DECODE: begin
                casez (instr_set)
                    STOR: NS = S3_STORE;
                    LOAD: NS = S4_LOAD;
						  BRANCH: NS = S6_BRANCH;
                    default: NS = S2_EXECUTE;
                endcase
            end

            S2_EXECUTE: NS = S0_FETCH;

            /* LOAD/STORE States */
            S3_STORE: NS = S0_FETCH;
            S4_LOAD:  NS = S5_DOUT;
            S5_DOUT:  NS = S0_FETCH;

				S6_BRANCH: NS = S0_FETCH;
            default: NS = S0_FETCH;
        endcase
    end

 // Decoder (combinational)
 decoder u_decoder (
        .instr_set(instr_set),
        .Imm_in   (Imm_in),
        .opcode   (opcode),
        .Rdest    (Rdest_select),
        .Rsrc     (Rsrc_select)
 );

    // Output logic (based on FSM state)
    always @(*) begin
        // defaults
        wEnable = 16'b0;

        Imm_select = 1'b0;

        pc_add_k = 8'd0000;
        pc_mux_selct = 1'b0; // use pc+1 or pc+k
        pc_en = 1'b0;

        we_a = 1'b0;
        en_a = 1'b0;
        en_b = 1'b0;
        ram_wen = 1'b0;

        lsc_mux_selct = 1'b0;

        fsm_alu_mem_selct = 1'b0;

        decoder_en = 1'b1;

        // immediate select (I-type except load/store)
        if ((opcode[7:4] != 4'h0) && (opcode != 8'h40) && (opcode != 8'h44))
            Imm_select = 1'b1;

        case (PS)
            S0_FETCH: begin
                // fetch instruction using PC as address
                en_a = 1'b1;
                lsc_mux_selct = 1'b0;
            end

            S1_DECODE: begin
                // decode happens continuously; no control outputs needed here
            end

            S2_EXECUTE: begin
                // normal ALU writeback
                pc_en = 1'b1;
                fsm_alu_mem_selct = 1'b0;

                // don't write on CMP/CMPI/WAIT
                if ((opcode == 8'h0B) || (opcode == 8'hB0) || (opcode == 8'h00))
                    wEnable = 16'b0;
                else
                    wEnable = (16'h0001 << Rdest_select);
            end

            /* Store: mem[Rdest] = Rsrc */
            S3_STORE: begin
                lsc_mux_selct = 1'b1; // address comes from Rdest
                en_a = 1'b1;
                we_a = 1'b1;
                ram_wen = 1'b1;
                pc_en = 1'b1;
            end

            /* Load read cycle: start mem read at addr=Rdest */
            S4_LOAD: begin
                lsc_mux_selct = 1'b1;
                en_a = 1'b1;
            end

            /* DOUT cycle: write mem data into Rsrc */
            S5_DOUT: begin
                lsc_mux_selct = 1'b1;
                fsm_alu_mem_selct = 1'b1;
                wEnable = (16'h0001 << Rsrc_select);
                pc_en = 1'b1;
            end
				
				S6_BRANCH: begin // RANCHE -- pc + k
						
						pc_en = 1'b1;
						
						if(check_flags(Flags_in)) begin
						
						// k == imm vlaue
						pc_add_k = Imm_in;
						// enable pc + k
						pc_mux_selct = 1;
	
						end
						
				end
		 endcase
    end


function integer check_flags(input [4:0] Flags_in);
    case (Flags_in)
        EQ:  begin
                if (Flags_in[1] == 1) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        NE:  begin
                if (Flags_in[1] == 0) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        GE:  begin
                if (Flags_in[1] == 1 | Flags_in[0] == 1) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        CS:  begin
                if (Flags_in[3] == 1) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        CC:  begin
                if (Flags_in[3] == 0) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        HI:  begin
                if (Flags_in[4] == 1) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        LS:  begin
                if (Flags_in[4] == 0) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        LO:  begin
                if (Flags_in[4] == 0 & Flags_in[1] == 0) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        HS:  begin
                if (Flags_in[4] == 1 | Flags_in[1] == 1) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        GT:  begin
                if (Flags_in[0] == 1) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        LE:  begin
                if (Flags_in[0] == 0) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        FS:  begin
                if (Flags_in[2] == 1) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        FC:  begin
                if (Flags_in[2] == 0) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        LT:  begin
                if (Flags_in[0] == 0 & Flags_in[1] == 0) begin
                    check_flags = 1; // Return 1 if condition is met
                end
             end
        UC:  begin
                // Your specific condition for UC here
                // If condition is met, return 1
                check_flags = 1;  // Placeholder for UC condition
             end
        XX:  begin
                // Your specific condition for XX here
                // If condition is met, return 1
                check_flags = 1;  // Placeholder for XX condition
             end
        // Default case to handle unexpected conditions
        default: begin
                    check_flags = 0; // Return 0 if no condition is met
                 end
    endcase
endfunction
endmodule
