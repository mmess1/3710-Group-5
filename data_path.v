module data_path#(parameter DATA_FILE="")
(
	input wire clk, reset, ram_we,

	/* Reg file */
	input [15:0] wEnable,

	/* ALU */
   input wire [7:0] opcode,
	output wire [4:0] Flags_out,

	/* RAM */
	input wire we_a, en_a, en_b,

	/* LS_cntr MUX */
	input wire lsc_mux_selct,

	/* PC */
	input wire [15:0] pc_add_k,
	input wire pc_mux_selct, pc_en,

	//extern -->fsm
	output wire [15:0]ram_out,
	output wire [15:0] pc_count,

	/* MUXS: */
	input wire fsm_alu_mem_selct,
	input wire [3:0] Rdest_select, Rsrc_select,
	input wire  [7:0] Imm_in,
	input wire Imm_select,

	// debug / board
	output wire [15:0] r0,
	output wire [15:0] r1,
	output wire [15:0] r2,
	output wire [15:0] r3,
	output wire [15:0] r4,
	output wire [15:0] r5,
	output wire [15:0] r6,
	output wire [15:0] r7,
	output wire [15:0] r8,
	output wire [15:0] r9,
	output wire [15:0] r10,
	output wire [15:0] r11,
	output wire [15:0] r12,
	output wire [15:0] r13,
	output wire [15:0] r14,
	output wire [15:0] r15

);


/************************************************************************
						INTERNAL WIRE
***********************************************************************/

/***************************
			RAM
***************************/

	/* ADDR == mem address */
	wire [15:0] ls_cntrl; // from LS_cntrol

	/* DOUT (data out == inst) */
	wire [15:0] q_a_wire;

	/* Enable wire */
	wire mem_we;
	assign mem_we = ram_we | we_a;

/***************************
			PC
***************************/
	// PC wires (out)
	wire [15:0] pc_out_wire;
	// PC wires (in)
	wire [15:0] adder_one_wire;
	wire [15:0] adder_k_wire;
	wire [15:0] pc_in_wire;

/***************************
ALU / MUX wires / Regfile
***************************/
	/* RDEST/RSRC MUX */
	wire[15:0] Rdest_mux_out;
	wire[15:0] Rsrc_Imm_mux_out;
	wire[15:0] Rsrc_mux_out;

	/* from ALU   --> reg file */
	wire [15:0] alu_bus;
	wire [15:0] alu_out;

	/* instruction buffer */
	wire [15:0] instr_buf_out;
	wire load_en;
	wire reset_hi;
	assign reset_hi = reset;

	// load the buffered instruction right after FETCH (during DECODE)
	assign load_en = (~mem_we) & (~lsc_mux_selct) & (~en_a);

/************************************************************************
						EXTERNAL WIRE: inputs
***********************************************************************/

RegBank RegBank (
    .clk    (clk),
    .wEnable(wEnable),
    .reset  (reset),
    .ALUBus (alu_bus),

    .r0     (r0),
    .r1     (r1),
    .r2     (r2),
    .r3     (r3),
    .r4     (r4),
    .r5     (r5),
    .r6     (r6),
    .r7     (r7),
    .r8     (r8),
    .r9     (r9),
    .r10    (r10),
    .r11    (r11),
    .r12    (r12),
    .r13    (r13),
    .r14    (r14),
    .r15    (r15)
);


mux_16to1 Rdest_mux (
    .sel (Rdest_select),
    .in0  (r0),
    .in1  (r1),
    .in2  (r2),
    .in3  (r3),
    .in4  (r4),
    .in5  (r5),
    .in6  (r6),
    .in7  (r7),
    .in8  (r8),
    .in9  (r9),
    .in10 (r10),
    .in11 (r11),
    .in12 (r12),
    .in13 (r13),
    .in14 (r14),
    .in15 (r15),
    .out(Rdest_mux_out)
);

mux_16to1 Rsrc_mux (
    .sel (Rsrc_select),
    .in0  (r0),
    .in1  (r1),
    .in2  (r2),
    .in3  (r3),
    .in4  (r4),
    .in5  (r5),
    .in6  (r6),
    .in7  (r7),
    .in8  (r8),
    .in9  (r9),
    .in10 (r10),
    .in11 (r11),
    .in12 (r12),
    .in13 (r13),
    .in14 (r14),
    .in15 (r15),
    .out(Rsrc_mux_out)
);

 mux_2to1 Rsrc_Imm_mux (
	.in0 (Rsrc_mux_out),
	.in1 (Imm_in),
	.sel (Imm_select),
	.out(Rsrc_Imm_mux_out)
);

 alu alu(
        .Rdest(Rdest_mux_out),
        .Rsrc_Imm (Rsrc_Imm_mux_out),
        .Opcode   (opcode),
        .Result   (alu_out),
        .Flags    (Flags_out)
);

/****************************
RAM
*******************************/
ram #(
	.DATA_WIDTH(16),
	.ADDR_WIDTH(10),
	.DATA_FILE0(DATA_FILE),
	.DATA_FILE1("")
) u_ram(
	.data_a(Rsrc_mux_out),
	.addr_a(ls_cntrl[9:0]),
	.we_a(mem_we),
	.clk(clk),
	.en_a(en_a),
	.q_a(q_a_wire)
);

/****************************
LSC control MUX: mem address comes from pc or Reg file
*******************************/
 mux_2to1 LS_cntl (

	.in0 (pc_out_wire),
	.in1 (Rdest_mux_out),
	.sel (lsc_mux_selct),
	.out(ls_cntrl)

);

/****************************
PC MUX:
*******************************/
assign adder_one_wire = pc_out_wire + 16'd1;
assign adder_k_wire   = pc_out_wire + $signed(pc_add_k);

 mux_2to1 pc_mux (
	.in0 (adder_one_wire),
	.in1 (adder_k_wire),
	.sel (pc_mux_selct),
	.out(pc_in_wire)
);

/****************************
PC
*******************************/
pc pc1 (
    .pc_en(pc_en),
    .rst(reset),
    .clk(clk),
	 .pc_in(pc_in_wire),
    .pc_count(pc_out_wire)
);

/****************************
ALU MUX: reg file get value from alu or mem
*******************************/
 mux_2to1 alu_mux (
	.in0 (alu_out),						// comes from alu
	.in1 (q_a_wire),					// comes from mem dout
	.sel (fsm_alu_mem_selct),
	.out(alu_bus)
);

/****************************
Instruction buffer:
	- during normal fetch, ram dout is the instruction
	- during load/store, ram dout becomes data, so feed buffered instruction to FSM
*******************************/
instr_buffer instr_buffer(
    .clk(clk),
    .reset(reset_hi),
    .load_en(load_en),
    .in(q_a_wire),
    .out(instr_buf_out)
);

assign ram_out = (lsc_mux_selct) ? instr_buf_out : q_a_wire;

assign pc_count = pc_out_wire;

endmodule