
module data_path(
	input wire clk, reset,
   input [15:0] wEnable, Imm_in,
   input wire [7:0] opcode, Rdest_select, Rsrc_select,
	input wire Imm_select
);
	 
	  wire [15:0] RegBank_out;

		wire [15:0] r0;
		wire [15:0] r1;
		wire [15:0] r2;
		wire [15:0] r3;
		wire [15:0] r4;
		wire [15:0] r5;

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
		
		wire[15:0] Rdest_mux_out;
		wire[15:0] Rsrc_Imm_mux_out;
		wire[15:0] Rsrc_mux_out;
		
		wire [15:0] alu_bus;
		wire [5:0] flags;
	 
		 
	 
RegBank RegBank (
    .clk    (clk),
    .regEnable(wEnable),
    .reset  (reset),

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
    .in15 (r15)
);

mux_16to1 Rsrc_mux (
    .sel (Rscst_select),

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
    .sel (Imm_select),
    .in0  (Imm_in),
    .in1  (Rsrc_mux_out),
	 .out(Rsrc_Imm_mux_out)
);

 alu alu(
        .Rdest(Rdest_mux_out),
        .Rsrc_Imm (Rsrc_Imm_mux_out),
        .Opcode   (opcode),
        .Result   (alu_bus),
        .Flags    (flags)
);

endmodule
