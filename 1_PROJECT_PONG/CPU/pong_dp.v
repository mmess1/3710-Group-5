module pong_dp #(parameter DATA_FILE="")
(
    input wire clk, reset, ram_we,

    input [8:0] player1_y, player2_y, // MMIO inputs for player positions (for testing)

    /* Reg file */
    input wire [15:0] wEnable,

    /* ALU */
    input  wire [7:0]  opcode,
    output wire [4:0]  Flags_out,

    /* RAM */
    input wire we_a, en_a, en_b,

    /* LS_cntr MUX */
    input wire lsc_mux_select,

    /* PC */
    input wire [15:0] pc_add_k,
    input wire pc_mux_select, pc_en,

    /* FSM reads instruction from here */
    output wire [15:0] ram_out,

    /* MUXs */
    input wire fsm_alu_mem_select,
    input wire [3:0]  Rdest_select, Rsrc_select,
    input wire [15:0] Imm_in,
    input wire        Imm_select,

    /* MMIO */
    output wire [15:0] ls_cntrl,       // LS_cntrl mux provided memory address
    output wire [15:0] Rsrc_mux_out,   // Rsrc provides store data / MMIO wr data

    input wire [15:0] mmio_rd_data,
    input wire        is_mmio
);

/************************************************************************
                        INTERNAL WIRES
************************************************************************/

/* Register file outputs */
wire [15:0] r0,  r1,  r2,  r3,  r4,  r5;
wire [15:0] r6,  r7,  r8,  r9,  r10;
wire [15:0] r11, r12, r13, r14, r15;

/* ALU result */
wire [15:0] alu_out;

/* MUX output */
wire [15:0] Rsrc_Imm_mux_out;
wire [15:0] Rdest_mux_out;

/* ALU bus into reg file */
wire [15:0] alu_bus;

/* RAM output */
wire [15:0] q_a;
assign ram_out = lsc_mux_select ? instr_new : q_a; // hold instr stable during load/store

/* PC */
wire [15:0] pc_out;
wire [15:0] pc_in;
wire [15:0] adder_one_wire = pc_out + 16'd1;
wire [15:0] adder_k_wire   = pc_out + pc_add_k;

/* Instruction buffer */
wire        load_en = ~en_a & ~lsc_mux_select; // latch during decode/execute, not fetch
wire [15:0] instr_old = q_a;
wire [15:0] instr_new;

/************************************************************************
                        MODULE INSTANTIATIONS
************************************************************************/

RegBank RegBank (
    .clk    (clk),
    .wEnable(wEnable),
    .reset  (reset),
    .ALUBus (alu_bus),
    .player1_y(player1_y),
    .player2_y(player2_y),
    .r0 (r0),  .r1 (r1),  .r2 (r2),  .r3 (r3),
    .r4 (r4),  .r5 (r5),  .r6 (r6),  .r7 (r7),
    .r8 (r8),  .r9 (r9),  .r10(r10), .r11(r11),
    .r12(r12), .r13(r13), .r14(r14), .r15(r15)
);

mux_16to1 Rdest_mux (
    .sel (Rdest_select),
    .in0 (r0),  .in1 (r1),  .in2 (r2),  .in3 (r3),
    .in4 (r4),  .in5 (r5),  .in6 (r6),  .in7 (r7),
    .in8 (r8),  .in9 (r9),  .in10(r10), .in11(r11),
    .in12(r12), .in13(r13), .in14(r14), .in15(r15),
    .out (Rdest_mux_out)
);

mux_16to1 Rsrc_mux (
    .sel (Rsrc_select),
    .in0 (r0),  .in1 (r1),  .in2 (r2),  .in3 (r3),
    .in4 (r4),  .in5 (r5),  .in6 (r6),  .in7 (r7),
    .in8 (r8),  .in9 (r9),  .in10(r10), .in11(r11),
    .in12(r12), .in13(r13), .in14(r14), .in15(r15),
    .out (Rsrc_mux_out)
);

mux_2to1 Rsrc_Imm_mux (
    .in0(Rsrc_mux_out),
    .in1(Imm_in),
    .sel(Imm_select),
    .out(Rsrc_Imm_mux_out)
);

alu alu (
    .Rdest    (Rdest_mux_out),
    .Rsrc_Imm (Rsrc_Imm_mux_out),
    .Opcode   (opcode),
    .Result   (alu_out),
    .Flags    (Flags_out)
);

ram #(.DATA_FILE0(DATA_FILE)) u_ram (  
    .data_a(Rsrc_mux_out),              
    .addr_a(ls_cntrl[9:0]),
    .we_a  (ram_we),
    .clk   (clk),
    .en_a  (en_a),
    .q_a   (q_a)
);

/* LS_cntl MUX: address from PC or Rdest */
mux_2to1 LS_cntl (
    .in0(pc_out),
    .in1(Rdest_mux_out), 
    .sel(lsc_mux_select),
    .out(ls_cntrl)
);

/* PC MUX: PC+1 or PC+k */
mux_2to1 pc_mux (
    .in0(adder_one_wire),
    .in1(adder_k_wire),
    .sel(pc_mux_select),
    .out(pc_in)
);

pc pc1 (
    .pc_en   (pc_en),
    .rst     (reset),
    .clk     (clk),
    .pc_in   (pc_in),
    .pc_count(pc_out)
);

/* ALU/mem MUX — selects MMIO read-back or RAM for loads */
wire [15:0] mem_rd_mux = is_mmio ? mmio_rd_data : q_a; 

mux_2to1 alu_mux (
    .in0(alu_out),
    .in1(mem_rd_mux),
    .sel(fsm_alu_mem_select),
    .out(alu_bus)
);

instr_buffer instr_buffer (
    .clk    (clk),
    .reset  (reset),
    .load_en(load_en),
    .in     (instr_old),
    .out    (instr_new)
);

endmodule
