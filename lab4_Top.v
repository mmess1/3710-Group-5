module lab4_Top(
    input  wire CLOCK_50, 

    
    input  wire [3:0]  KEY,
  //  output wire [9:0]  LEDR,
  //  output wire [6:0]  HEX0,
  //  output wire [6:0]  HEX1,
 //   output wire [6:0]  HEX2,
    output wire [6:0]  HEX3
    
);

// GLOBAL WIRES
wire reset = KEY[0];
wire clk_slow;

// Program Counter
wire [15:0] pc_count;

// Instruction
reg  [15:0] instr_set;

// FSM → data path
wire pc_en;
wire [15:0] wEnable;
wire [15:0] Imm_in;
wire [7:0]  opcode;
wire [3:0]  Rdest_sel;
wire [3:0]  Rsrc_sel;
wire        Imm_sel;
wire [15:0] decoder;
wire        decoder_en;

wire [15:0] data_out;

// Data Path
wire [4:0]  Flags_out;
// wire [15:0] r0,r1,r2,r3,r4,r5,r6,r7;
// wire [15:0] r8,r9,r10,r11,r12,r13,r14,r15;

// FSM
decode_fsm fsm (
    .clk(clk_slow),
    .reset(reset),
    // .Flags_out(Flags_out),
    .instr_set(instr_set), // input
    .pc_en(pc_en),
	 .w_en(wEnable),
    .opcode(opcode),

  
	 .imm_sel(Imm_sel),
	 
	 .rsrc(Rsrc_sel),
	 .rdest(Rdest_sel)
);

// Clock Divider
clock_div #(.DIV(5_000_000)) u_div (
    .clk_in (CLOCK_50),
    .reset  (reset),
    .clk_out(clk_slow)
);

// Decoder (commented-out)
/*
decoder dc (
    .instr_set (instr_set),
    .clk       (clk_slow),
    .reset     (reset),
    .wEnable   (wEnable),
    .Imm_in    (Imm_in),
    .Rdest     (Rdest_sel),
    .Rsrc_Imm  (Rsrc_sel),
    .Imm_select(Imm_sel)
);
*/

// Data Path
data_path dp (
    .clk(clk_slow),
    .reset(reset),
    .wEnable(wEnable),
    .Imm_in(Imm_in),
    .opcode(opcode),
    .Rdest_select(Rdest_sel),
    .Rsrc_select(Rsrc_sel),
    .data_out(data_out)
);

// Program Counter
pc pc1 (
    .pc_en(pc_en),
    .rst(reset),
    .clk(clk_slow),
    .pc_count(pc_count)
);

// Instruction ROM
always @(posedge clk_slow or negedge reset) begin
    if (!reset)
        instr_set <= 16'b0;
    else begin
        case (pc_count)
            3'd0: instr_set <= 16'b0101_0001_0000_0101;
            3'd1: instr_set <= 16'b0000_0010_0001_1101;
            3'd2: instr_set <= 16'b0000_0011_0001_0101;
            3'd3: instr_set <= 16'b0000_0100_0011_1001;
            default: instr_set <= 16'b0;
        endcase
    end
end

// HEX function
function [6:0] hex7;
    input [3:0] x;
    begin
        case (x)
            4'h0: hex7 = 7'b1000000;
            4'h1: hex7 = 7'b1111001;
            4'h2: hex7 = 7'b0100100;
            4'h3: hex7 = 7'b0110000;
            4'h4: hex7 = 7'b0011001;
            4'h5: hex7 = 7'b0010010;
            4'h6: hex7 = 7'b0000010;
            4'h7: hex7 = 7'b1111000;
            4'h8: hex7 = 7'b0000000;
            4'h9: hex7 = 7'b0010000;
            4'hA: hex7 = 7'b0001000;
            4'hB: hex7 = 7'b0000011;
            4'hC: hex7 = 7'b1000110;
            4'hD: hex7 = 7'b0100001;
            4'hE: hex7 = 7'b0000110;
            4'hF: hex7 = 7'b0001110;
            default: hex7 = 7'b1111111;
        endcase
    end
endfunction

// The commented-out assignments for HEX could be re-enabled if needed:
 //assign HEX0 = hex7(data_out[3:0]);
// assign HEX1 = hex7(data_out[3:0]);
 assign HEX2 = hex7(pc_count[3:0]);
 assign HEX3 = hex7(pc_count [7:4]);

// assign pc_current = pc_count; // Corrected assignment for pc_current

endmodule
