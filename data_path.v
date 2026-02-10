module data_path(
	input wire clk, reset, ram_we,
   input [15:0] wEnable, Imm_in,
   input wire [7:0] opcode, 
   input wire [3:0] Rdest_select, Rsrc_select,
	input wire Imm_select,
	// output wire [4:0] Flags_out,
	output wire [15:0] instr_out
);
	 
	 
	 
	 
/************************************************************************
							INTERNAL WIRE
***********************************************************************/

	//RAM 
	wire [9:0] addr_a, addr_b;
	wire we_a, we_b, clk, en_a, en_b;
	wire [15:0] q_a, q_b;
	wire [15:0] RegBank_out;
   wire [9:0] addr_a, addr_b;
	
	//wire  [15:0] data_ram_in_a, data_ram_in_b; // rsrc

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
		
		// RDEST/RSRC MUX
		wire[15:0] Rdest_mux_out;
		wire[15:0] Rsrc_Imm_mux_out;
		wire[15:0] Rsrc_mux_out;
		
		//wire [15:0] alu_bus;
		wire [4:0] Flags_out;
		
		// from pc
		wire [15:0] pc_out;

// internal
wire pc_mux_selct;

// intern from pac
wire [15:0] pc_in, ls_c_wire;

// pc mux addders
wire [15:0] adder_one, adder_k

		// internal
	wire [15:0] alu_bus,
		
/************************************************************************
							EXTERNAL WIRE: inputs
***********************************************************************/
	// RAM:
	// wire  [15:0] data_ram_in_a, data_ram_in_b;
	wire we_a;
	wire en_a;
	wire en_b;
	
	// external from fsm
	wire [15:0] inst_branch; 
	
	//extern -->fsm
	wire [15:0]ram_out;
	
	// extern --> from fsm to ..
	wire fsm_alu_mem_selct;
	
		//ex
		wire load_en;

		// external
		wire [15:0] instr_old,

		// external 
		wire [15:0]instr_new;

	
			 
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
	.addr_a(ls_c_wire),
	.addr_b(), // IGNORE
	
	.we_a(ram_we), 	
	.we_b(0), // IGNORE
	.clk(clk), 
	.en_a(), 
	.en_b(0),			// IGNORE
	.q_a(),			// USE (data out)
	.q_b()		//IGNOR FOR NOW
)

/****************************
LSC control MUX: meme write addss comes from pc or Reg file
*******************************/
 mux_2to1 LS_cntl (
	.in0 (pc_out),
	.in1 (Rdest_mux_out),
	.sel (pc_mux_selct),
	.out(ls_c_wire)
);

/****************************
PC MUX:
*******************************/
 mux_2to1 pc_mux (
	.in0 (adder_one),
	.in1 (adder_k),
	.sel (pc_mux_selct),
	.out(pc_in)
);
/****************************
PC adder 1:
*******************************/
 pc_inc adder_on (
	.in(pc_out),
	.k (1),
	.sum(adder_one)
);
/****************************
PC adder k:
*******************************/
 pc_inc add_kk(
	.in(pc_out),
	.k (inst_branch),
	.sel (pc_mux_selct),
	.sum(adder_k)
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
	.in0 (ram_out), 							// comes from ram
	.in1 (alu_out), 				   // from alu
	.sel (fsm_alu_mem_selct),
	.out(alu_bus)
);


/****************************
ALU MUX: reg file get value from alue or mem
*******************************/
instr_buffer instr_buffer(
    .clk(clk)       // Clock signal
    .reset(reset),    // Reset signal
    .load_en(load_en)     // Control signal to load data
    .in(instr_old),   // 16-bit input instruction
    .out(instr_new)   // 16-bit output instruction
);

endmodule