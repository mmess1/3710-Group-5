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
   output reg         imm_sel      // Immediate select (R/I type)
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
