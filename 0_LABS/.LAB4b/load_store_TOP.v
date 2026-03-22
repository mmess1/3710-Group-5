module branch_TOP(
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    output wire [9:0]  LEDR,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3,
	 output wire [6:0]  HEX4,
	 output wire [6:0]  HEX5
);

    // KEY[0] on the DE1 is active-low
    wire reset_n = KEY[0];

    wire clk_slow;

    // Clock Divider (active-low reset)
    clock_div #(.DIV(6_000_000)) u_div (
        .clk_in (CLOCK_50),
        .reset  (reset_n),
        .clk_out(clk_slow)
    );

    // FSM <-> datapath wires
    wire [15:0] wEnable;
    wire [7:0]  opcode;
    wire [3:0]  Rdest_select;
    wire [3:0]  Rsrc_select;
    wire [15:0] Imm_in;
    wire        Imm_select;

    wire we_a, en_a, en_b, ram_wen;
    wire lsc_mux_selct;

    wire [7:0] pc_add_k;
    wire pc_mux_selct, pc_en;

    wire fsm_alu_mem_selct;
    wire decoder_en;

    wire [15:0] ram_out;

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

    wire [4:0] Flags_out;

    wire [15:0] pc_count;

    branch_FSM fsm(
        .clk(clk_slow),
        .reset(reset_n),

        .instr_set(ram_out),
        .Flags_in(Flags_out),

        .wEnable(wEnable),

        .opcode(opcode),
        .Rdest_select(Rdest_select),
        .Rsrc_select(Rsrc_select),
        .Imm_in(Imm_in),
        .Imm_select(Imm_select),

        .we_a(we_a),
        .en_a(en_a),
        .en_b(en_b),
        .ram_wen(ram_wen),

        .lsc_mux_selct(lsc_mux_selct),

        .pc_add_k(pc_add_k),
        .pc_mux_selct(pc_mux_selct),
        .pc_en(pc_en),

        .fsm_alu_mem_selct(fsm_alu_mem_selct),
        .decoder_en(decoder_en)
    );

    data_path #(
        // NOTE: if Quartus can't find this, change to an absolute path like other labs
        .DATA_FILE("C:/Users/genet/altera_lite/quartus/ece3710/3710-Group-5/util/branch.hex")
    ) dp(
        .clk(clk_slow),
        .reset(reset_n),
        .ram_we(ram_wen),

        .wEnable(wEnable),

        .opcode(opcode),
        .Flags_out(Flags_out),

        .we_a(we_a),
        .en_a(en_a),
        .en_b(en_b),
		  .load_en(load_en),

        .lsc_mux_selct(lsc_mux_selct),

        .pc_add_k(pc_add_k),
        .pc_mux_selct(pc_mux_selct),
        .pc_en(pc_en),

        .ram_out(ram_out),
        .pc_count(pc_count),

        .fsm_alu_mem_selct(fsm_alu_mem_selct),
        .Rdest_select(Rdest_select),
        .Rsrc_select(Rsrc_select),
        .Imm_in(Imm_in),
        .Imm_select(Imm_select),

        .r0(r0),
        .r1(r1),
        .r2(r2),
        .r3(r3),
        .r4(r4),
        .r5(r5),
        .r6(r6),
        .r7(r7),
        .r8(r8),
        .r9(r9),
        .r10(r10),
        .r11(r11),
        .r12(r12),
        .r13(r13),
        .r14(r14),
        .r15(r15)
    );

    // Simple debug display:
    //  - HEX3:HEX0 shows 16-bit pc_count
	 //  - LEDR shows the current k value

    hex7seg h0(.hex(pc_count[3:0]),		.seg(HEX0));
    hex7seg h1(.hex(pc_count[7:4]),		.seg(HEX1));
	 hex7seg h2(.hex(pc_count[11:8]),	.seg(HEX2));
	 hex7seg h3(.hex(pc_count[15:12]),	.seg(HEX3));
	 
	 hex7seg h4(.hex(r5[3:0]),			.seg(HEX4));
	 hex7seg h5(.hex(r6[3:0]), 			.seg(HEX5));

    assign LEDR = pc_add_k[7:0];

endmodule
