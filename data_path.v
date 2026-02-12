module data_path(
	
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
	
	/* MUXS: */ 
	input wire fsm_alu_mem_selct,
	input wire [3:0] Rdest_select, Rsrc_select,
	input wire  [15:0] Imm_in,
	input wire Imm_select

);
	 
	 
/************************************************************************
							INTERNAL WIRE
***********************************************************************/

/***************************
			RAM
***************************/
	
	/* ADDR == mem address */ 
	wire [15:0] ls_cntrl; // from LS_cntrol
	
	/* DIN (data in from rdest mux */
		/* Rdest_mux_out; */
	
	/* DOUT (data out == inst) */
		wire [15:0] q_a_wire; 
		wire [15:0] q_b_wire; // represent instrucion set --> only (a) used for now
	
	/* Enable wire */
	//wire we_a_wire; 
	//wire we_b_wire; 		// write enable
	//wire en_a_wire; 
	//wire en_b_wire;		// read enable
	
	
   wire [9:0] addr_a_wire;
	wire	[9:0] addr_b_wire;   // FIX ME

/***************************
			PC
***************************/
	// PC wires (out)
	wire [15:0] pc_out_wire;
	// PC wires (in)
	wire [15:0] adder_one_wire;
	wire [15:0] adder_k_wire;

	// mux select
	wire pc_mux_selct_wire;
	
	
/***************************
ALU / MUX wires / Regfile
***************************/
	/* Reg file */
		wire [15:0] r0;
		wire [15:0] r1;
		wire [15:0] r2;
		wire [15:0] r3;
		wire [15:0] r4;
		
		wire [15:0] r6;
		wire [15:0] r7;
		wire [15:0] r8;
		wire [15:0] r9;
		wire [15:0] r10;

		wire [15:0] r11;
		wire [15:0] r12;
		wire [15:0] r13;
		wire [15:0] r14;
		wire [15:0] r15;
		
		/* RDEST/RSRC MUX */
		wire[15:0] Rdest_mux_out;
		wire[15:0] Rsrc_Imm_mux_out;
		wire[15:0] Rsrc_mux_out;
		
		/* from ALU   --> reg file */
		wire [15:0] alu_bus;
		
		
/************************************************************************
							EXTERNAL WIRE: inputs
***********************************************************************/

	
			 
RegBank RegBank (
    .clk    (clk),
    .regEnable(wEnable),
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
ram ram (

	.data_a(Rdest_mux_out),  // USE (data in)
	.data_b(), //IGNORE
	.addr_a(ls_cntrl),
	.addr_b(), // IGNORE
	
	.we_a(ram_we), 	
	.we_b(0), // IGNORE
	.clk(clk), 
	.en_a(en_a), 
	.en_b(0),			// IGNORE
	.q_a(q_a),			// USE (data out == insturction set)
	.q_b()		//IGNOR FOR NOW
);

/****************************
LSC control MUX: meme write addss comes from pc or Reg file
*******************************/
 mux_2to1 LS_cntl (

	.in0 (pc_out),
	.in1 (Rdest_mux_out),
	.sel (lsc_mux_selct),
	.out(ls_cntrl)

);
/****************************
PC MUX:
*******************************/
 mux_2to1 pc_mux (
	.in0 (adder_one_wire),
	.in1 (adder_k_wire),
	.sel (pc_mux_select),
	.out(pc_in)
);

/****************************
PC adder 1:
*******************************/
 pc_inc adder_one (
	.in(pc_out),
	.k (1),
	.sum(adder_one_wire)
);

/****************************
PC adder k:
*******************************/
 pc_inc add_kk(
	.in(pc_out),
	.k (pc_add_k),
	.sum(adder_k_wire)
);

/****************************
PC 
*******************************/
pc pc1 (
    .pc_en(pc_en),
    .rst(reset),
    .clk(clk),
    .pc_count(pc_out)
);

/****************************
ALU MUX: reg file get value from alue or mem
*******************************/
 mux_2to1 alu_mux (
	.in0 (alu_out), 							// comes from alue
	.in1 (ram_out), 				   // from ram
	.sel (fsm_alu_mem_selct),
	.out(alu_bus)
);


/****************************
ALU MUX: reg file get value from alue or mem
*******************************/
instr_buffer instr_buffer(
    .clk(clk),      // Clock signal
    .reset(reset),    // Reset signal
    .load_en(load_en),     // Control signal to load data
    .in(instr_old),   // 16-bit input instruction
    .out(instr_new)   // 16-bit output instruction
);

endmodule