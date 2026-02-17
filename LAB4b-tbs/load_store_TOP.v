module load_store_TOP(
    
	 input  wire CLOCK_50, 
    input  wire [3:0]  KEY
   // output wire [9:0]  LEDR,
  //  output wire [6:0]  HEX0,
  //  output wire [6:0]  HEX1,
  //  output wire [6:0]  HEX2,
  //  output wire [6:0]  HEX3
    
);

// GLOBAL WIRES
wire reset = KEY[0];
wire clk_slow;

/***************************
			FSM --> DataPath
***************************/
/* Ram */
wire we_a; 
wire en_a; 
wire en_b; 
wire ram_we;
/* LS_cntr MUX */
wire lsc_mux_selct;
/* PC */
wire [15:0] pc_add_k;
wire pc_mux_selct;
wire pc_en;
/* Reg file */
wire [15:0] wEnable;
/* ALU/ Muxes */ 
wire [15:0] imm_in;
wire [7:0]  opcode;
wire [3:0]  Rdest_sel;
wire [3:0]  Rsrc_sel;
wire        imm_sel;
wire fsm_alu_mem_selct;

/***************************
			Data Path --> FSM
***************************/
wire [4:0] Flags;
wire [15:0] ram_out;
reg [15:0] instr_set;



// FSM
decode_fsm fsm (

/*global */
 .clk(clk_slow),
 .reset(reset),
/* PC */
.pc_add_k(pc_add_k),
.pc_mux_selct(pc_mux_selct),
.pc_en(pc_en),
/* LS_cntr MUX */
.lsc_mux_selct(lsc_mux_selct),
/* RAM */
.ram_we(ram_we),
.we_a(we_a), 
.en_a(en_a), 
.en_b(en_b),
ram_out(ram_out), // data out ---> FIX ME
/* ALU */
.opcode(opcode),
.Flags_in(Flags),
/* Reg file */
.wEnable(wEnable),

/* MUXS: */ 
.fsm_alu_mem_selct(fsm_alu_mem_selct),
.Rdest_select(Rdest_sel),
.Rsrc_select(Rsrc_sel),
.Imm_in(imm_in),
.Imm_select(imm_sel),

.instr_set(instr_set)

);


	
// Data Path
data_path dp (

/*global */
 .clk(clk_slow),
 .reset(reset),
/* PC */
.pc_add_k(pc_add_k),
.pc_mux_selct(pc_mux_selct),
/* LS_cntr MUX */
.lsc_mux_selct(lsc_mux_selct),
/* RAM */
.ram_we(ram_we),
.we_a(we_a), 
.en_a(en_a), 
.en_b(en_b),
ram_out(ram_out), // data out ---> FIX ME
/* ALU */
.opcode(opcode),
.Flags_out(Flags),
/* Reg file */
.wEnable(wEnable),

/* MUXS: */ 
.fsm_alu_mem_selct(fsm_alu_mem_selct),
.Rdest_select(Rdest_sel),
.Rsrc_select(Rsrc_sel),
.Imm_in(imm_in),
.Imm_select(imm_sel)
);


// Clock Divider
clock_div #(.DIV(5_000_000)) u_div (
    .clk_in (CLOCK_50),
    .reset  (reset),
    .clk_out(clk_slow)
);



// Instruction ROM
/*
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
*/

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
//assign HEX1 = hex7(data_out[3:0]);
 //assign HEX2 = hex7(pc_count[3:0]);
 //assign HEX3 = hex7(pc_count [7:4]);

// assign pc_current = pc_count; // Corrected assignment for pc_current

endmodule
