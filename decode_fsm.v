module decode_fsm (
    input  wire        clk,
    input  wire        reset,     // active-low reset

    // instruction set coming from hard-coded values in top-level module
    input  wire [15:0]  instr_set;  

    // FSM outputs (match slide names)
    output reg         pc_en,       // PCe
    output reg         w_en,         // write enable
    output reg  [3:0]  rsrc,
    output reg  [3:0]  rdest,
    output reg  [7:0]  opcode,
    output reg         imm_sel,     // R/I
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
            S0_FETCH:   NS = S1_DECODE;

            S1_DECODE: 	NS = S2_EXECUTE; 

            S2_EXECUTE: NS = S0_FETCH;

            default:    NS = S0_FETCH;
        endcase
    end
	 
	 
    // Output logic 
    always @(*) begin
        // set defaults
		  pc_en   = 1'b0;
		  w_en	 = 1'b0;
        rsrc    = 4'b0000;
        rdest   = 4'b0000;
        opcode  = 8'h00;
        imm_sel = 1'b0;


        case (PS)
            S0_FETCH: begin
					 // does nothing
                pc_en   = 1'b0;
                w_en     = 1'b0;
            end

            S1_DECODE: begin
                pc_en   = 1'b0;
					 
					 decoder u_decoder(
						.instr_set(instr_set),
						.clk(clk),
						.reset(reset),
						.wEnable(w_en),
						.Imm_select(imm_sel)
						.opcode(opcode),
						.Rdest(rdest),
						.Rsrc_Imm(rsrc),
					);

            end

            S2_EXECUTE: begin
                pc_en   = 1'b1;          //  PC increments
					 w_en		= 1'b1;			  // 	write to reg file
            end
        endcase
    end

endmodule
