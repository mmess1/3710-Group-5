module arithmetic_comp_FSM #(
                           parameter BIT_WIDTH    = 16,
                           parameter OPCODE_WIDTH =  8,
                           parameter FLAG_WIDTH   =  5,
                           parameter SEL_WIDTH    =  4
                          )
                          (
                           input wire                           Clk,
                           input wire                           Rst,
                           input [FLAG_WIDTH-1:0]             Flags,
                           output reg [SEL_WIDTH-1:0]  Rsrc_mux_sel, 
                           output reg [SEL_WIDTH-1:0] Rdest_mux_sel, 
                           output reg                   Imm_mux_sel,
                           output reg [BIT_WIDTH-1:0]       Imm_val,
                           output reg [OPCODE_WIDTH-1:0]     Opcode,
                           output reg [BIT_WIDTH-1:0]   Reg_File_En
                          );

    localparam s_init = 4'd0; // Initial state
    localparam s_load_r0 = 4'd1;
    localparam s_load_r1 = 4'd2;
    localparam s_add_r2 = 4'd3;
    localparam s_sub_r3 = 4'd4;
    localparam s_subi_r4 = 4'd5;
    localparam s_cmp_r0_r1 = 4'd6;
    localparam s_cmpi_r4_0 = 4'd7;
    localparam s_load_r6 = 4'd8;
    localparam s_load_r7 = 4'd9;
    localparam s_addu_r8 = 4'd10;
    localparam s_pass = 4'd11;
    localparam s_fail = 4'd12;
    localparam s_final = 4'd13;
	 
	 localparam s_and_r9  = 5'd14;
localparam s_or_r10  = 5'd15;
localparam s_xor_r11 = 5'd16;
localparam s_not_r12 = 5'd17;


    reg [4:0] PS; // Present State
    reg [4:0] NS; // Next State

    localparam [7:0] ADD   = 8'b0000_0101;
    localparam [7:0] ADDU  = 8'b0000_0110;
    localparam ADDUI = 8'b0110_xxxx;
    localparam ADDC  = 8'b0000_0111;
    localparam ADDCI = 8'b0111_xxxx;
    localparam [7:0] SUB   = 8'b0000_1001;
    localparam [7:0] SUBI  = 8'b1001_0000;
    localparam [7:0] CMP   = 8'b0000_1011;
    localparam [7:0] CMPI  = 8'b1011_0000;
    localparam AND   = 8'b0000_0001;
    localparam ANDI  = 8'b0001_xxxx;
    localparam OR    = 8'b0000_0010;
    localparam ORI   = 8'b0010_xxxx;
    localparam XOR   = 8'b0000_0011;
    localparam XORI  = 8'b0011_xxxx;
    localparam LSH   = 8'b1000_0100;
    localparam LSHI  = 8'b1000_000x;
    localparam ARSH  = 8'b1000_0110;
    localparam ARSHI = 8'b1000_001x;
    localparam RSH   = 8'b1000_100x;
    localparam RSHI  = 8'b1000_101x;
    localparam NOT   = 8'b0000_0100;
    localparam [7:0] NOP   = 8'b0000_0000;



    localparam [7:0] MOV   = 8'b0000_1101;
    localparam [7:0] MOVI  = 8'b1101_0000;


    // Init PS to the inital state or next state
    always @(posedge Clk, negedge Rst) begin
        if (~Rst)
            PS <= s_init;
        else
            PS <= NS;
    end

    // Set Next State
    always @(*) begin
        case (PS)
            s_init: NS = s_load_r0;
            s_load_r0: NS = s_load_r1;
            s_load_r1: NS = s_add_r2;
            s_add_r2: NS = s_sub_r3;
            s_sub_r3: NS = s_subi_r4;
            s_subi_r4: NS = s_cmp_r0_r1;
            s_cmp_r0_r1: NS = s_cmpi_r4_0;

            s_cmpi_r4_0: begin
                if (Flags[1] == 1'b1) NS = s_load_r6;
                else                  NS = s_fail;
            end

            s_load_r6: NS = s_load_r7;
				s_load_r7:  NS = s_addu_r8;
				s_addu_r8:  NS = s_and_r9;

				s_and_r9:   NS = s_or_r10;
				s_or_r10:   NS = s_xor_r11;
				s_xor_r11:  NS = s_not_r12;
				s_not_r12:  NS = s_pass;

            s_pass: NS = s_final;
            s_fail: NS = s_final;
            s_final: NS = s_final;
				
            default: NS = s_init;
        endcase
    end

   // Set Outputs
    always @(*) begin
        Rsrc_mux_sel =  4'dx;
        Rdest_mux_sel =  4'dx;
        Imm_mux_sel =  1'bx;
        Imm_val = 16'dx;
        Opcode =  8'dx;
        Reg_File_En = 16'dx;

        case (PS)

            // INIT
            s_init: begin
                Rsrc_mux_sel = 4'd0;
                Rdest_mux_sel = 4'd0;
                Imm_mux_sel = 1'b0;
                Imm_val = 16'd0;
                Opcode = NOP;
                Reg_File_En = 16'b0000_0000_0000_0000;
            end

            // R0 = 16'h7FFF
            s_load_r0: begin
                Rsrc_mux_sel = 4'd0;
                Rdest_mux_sel = 4'd0;
                Imm_mux_sel = 1'b1;
                Imm_val = 16'h7FFF;
                Opcode = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0001; //R0
            end

            // R1 = 16'h0001
            s_load_r1: begin
                Rsrc_mux_sel = 4'd1;
                Rdest_mux_sel = 4'd1;
                Imm_mux_sel = 1'b1;
                Imm_val = 16'h0001;
                Opcode = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0010; //R1
            end

            // R2 = R0 + R1  (signed ADD, overflow test)
            s_add_r2: begin
                Rsrc_mux_sel = 4'd1;       // R1
                Rdest_mux_sel = 4'd0;       // R0
                Imm_mux_sel = 1'b0;       //register
                Imm_val = 16'd0;
                Opcode = ADD;
                Reg_File_En = 16'b0000_0000_0000_0100; //R2
            end

            // R3 = R1 - R0  (signed SUB, negative test)
            s_sub_r3: begin
                Rsrc_mux_sel = 4'd0;       // R0
                Rdest_mux_sel = 4'd1;       // R1
                Imm_mux_sel = 1'b0;       //register
                Imm_val = 16'd0;
                Opcode = SUB;
                Reg_File_En = 16'b0000_0000_0000_1000; //R3
            end

            // R4 = R0 - 16'h7FFF  (SUBI => should become 0)
            s_subi_r4: begin
                Rsrc_mux_sel = 4'd0;       // don't-care (imm used)
                Rdest_mux_sel = 4'd0;       // R0 as left operand
                Imm_mux_sel = 1'b1;       //immediate
                Imm_val = 16'h7FFF;
                Opcode = SUBI;
                Reg_File_En = 16'b0000_0000_0001_0000; //R4
            end

            // CMP R0 ? R1 (flags only, no write)
            s_cmp_r0_r1: begin
                Rsrc_mux_sel = 4'd1;       // R1
                Rdest_mux_sel = 4'd0;       // R0
                Imm_mux_sel = 1'b0;       //register
                Imm_val = 16'd0;
                Opcode = CMP;
                Reg_File_En = 16'b0000_0000_0000_0000; // no write
            end

            // CMPI R4 ? 0 (flags only, branches on Z)
            s_cmpi_r4_0: begin
                Rsrc_mux_sel = 4'd0;       // don't-care (imm used)
                Rdest_mux_sel = 4'd4;       // R4
                Imm_mux_sel = 1'b1;       //immediate
                Imm_val = 16'h0000;
                Opcode = CMPI;
                Reg_File_En = 16'b0000_0000_0000_0000; // no write
            end

            // R6 = 0xFFFF
            s_load_r6: begin
                Rsrc_mux_sel = 4'd6;
                Rdest_mux_sel = 4'd6;
                Imm_mux_sel = 1'b1;
                Imm_val = 16'hFFFF;
                Opcode = MOVI;
                Reg_File_En = 16'b0000_0000_0100_0000; // enable R6
            end

            // R7 = 0x0001
            s_load_r7: begin
                Rsrc_mux_sel = 4'd7;
                Rdest_mux_sel = 4'd7;
                Imm_mux_sel = 1'b1;
                Imm_val = 16'h0001;
                Opcode = MOVI;
                Reg_File_En = 16'b0000_0000_1000_0000; // enable R7
            end

            // R8 = R6 + R7 (ADDU => expect 0 with Carry=1)
            s_addu_r8: begin
                Rsrc_mux_sel = 4'd7;       // R7
                Rdest_mux_sel = 4'd6;       // R6
                Imm_mux_sel = 1'b0;
                Imm_val = 16'd0;
                Opcode = ADDU;
                Reg_File_En = 16'b0000_0001_0000_0000; //R8
            end
				
				// R9 = R6 AND R7  (FFFF & 0001 = 0001)
				s_and_r9: begin
					 Rsrc_mux_sel  = 4'd7;       // R7
					 Rdest_mux_sel = 4'd6;       // R6
					 Imm_mux_sel   = 1'b0;
					 Imm_val       = 16'd0;
					 Opcode        = AND;
					 Reg_File_En   = 16'b0000_0010_0000_0000; // R9
				end

				// R10 = R0 OR R1  (7FFF | 0001 = 7FFF)
				s_or_r10: begin
					 Rsrc_mux_sel  = 4'd1;       // R1
					 Rdest_mux_sel = 4'd0;       // R0
					 Imm_mux_sel   = 1'b0;
					 Imm_val       = 16'd0;
					 Opcode        = OR;
					 Reg_File_En   = 16'b0000_0100_0000_0000; // R10
				end

				// R11 = R7 XOR R7  (0001 ^ 0001 = 0000)
				s_xor_r11: begin
					 Rsrc_mux_sel  = 4'd7;       // R7
					 Rdest_mux_sel = 4'd7;       // R7
					 Imm_mux_sel   = 1'b0;
					 Imm_val       = 16'd0;
					 Opcode        = XOR;
					 Reg_File_En   = 16'b0000_1000_0000_0000; // R11
				end

				// R12 = NOT R4   (~0000 = FFFF)
				s_not_r12: begin
					 Rsrc_mux_sel  = 4'd0;       // don't care
					 Rdest_mux_sel = 4'd4;       // R4
					 Imm_mux_sel   = 1'b0;
					 Imm_val       = 16'd0;
					 Opcode        = NOT;
					 Reg_File_En   = 16'b0001_0000_0000_0000; // R12
				end

            // PASS: R15 = 16'h1111
            s_pass: begin
                Rsrc_mux_sel = 4'd15;
                Rdest_mux_sel = 4'd15;
                Imm_mux_sel = 1'b1;
                Imm_val = 16'h1111;
                Opcode = MOVI;
                Reg_File_En = 16'b1000_0000_0000_0000; //R15
            end

            // FAIL: R15 = 16'hDEAD
            s_fail: begin
                Rsrc_mux_sel = 4'd15;
                Rdest_mux_sel = 4'd15;
                Imm_mux_sel = 1'b1;
                Imm_val = 16'hDEAD;
                Opcode = MOVI;
                Reg_File_En = 16'b1000_0000_0000_0000; //R15
            end

            // FINAL: hold
            s_final: begin
                Rsrc_mux_sel = 4'd0;
                Rdest_mux_sel = 4'd0;
                Imm_mux_sel = 1'b0;
                Imm_val = 16'd0;
                Opcode = NOP;
                Reg_File_En = 16'b0000_0000_0000_0000;
            end

        endcase
    end

endmodule

module arithmetic_comp_FSM_TOP (
    input  wire Clk,
    input  wire Rst
);

    wire [3:0]  Rsrc_mux_sel;
    wire [3:0]  Rdest_mux_sel;
    wire        Imm_mux_sel;
    wire [15:0] Imm_val;
    wire [7:0]  Opcode;
    wire [15:0] Reg_File_En;

    wire [4:0]  Flags;

    wire reset_hi = ~Rst;

    arithmetic_comp_FSM FSM (
        .Clk(Clk),
        .Rst(Rst),
        .Flags(Flags),

        .Rsrc_mux_sel(Rsrc_mux_sel),
        .Rdest_mux_sel(Rdest_mux_sel),
        .Imm_mux_sel(Imm_mux_sel),
        .Imm_val(Imm_val),
        .Opcode(Opcode),
        .Reg_File_En(Reg_File_En)
    );

    data_path DP (
        .clk(Clk),
        .reset(reset_hi),

        .wEnable(Reg_File_En),
        .Imm_in(Imm_val),
        .opcode(Opcode),

        .Rdest_select(Rdest_mux_sel),
        .Rsrc_select(Rsrc_mux_sel),
        .Imm_select(Imm_mux_sel),

        .Flags_out(Flags)
    );

endmodule

`timescale 1ns/1ps

module tb_arithmetic_comp;

    reg Clk;
    reg Rst;

    arithmetic_comp_FSM_TOP dut (
        .Clk(Clk),
        .Rst(Rst)
    );

    initial begin
        Clk = 0;
        forever #5 Clk = ~Clk;
    end

    initial begin
        Rst = 0;       // ACTIVE-LOW reset asserted
        #20;
        Rst = 1;       // release reset
        #500;
        $stop;
    end

endmodule

/*
restart -f
delete wave *

add wave sim:/tb_arithmetic_comp/Clk
add wave sim:/tb_arithmetic_comp/Rst

add wave -divider "FSM Status"
add wave sim:/tb_arithmetic_comp/dut/FSM/PS
add wave sim:/tb_arithmetic_comp/dut/FSM/NS

add wave -divider "Control Signals"
add wave sim:/tb_arithmetic_comp/dut/FSM/Opcode
add wave sim:/tb_arithmetic_comp/dut/FSM/Imm_mux_sel
add wave sim:/tb_arithmetic_comp/dut/FSM/Imm_val
add wave sim:/tb_arithmetic_comp/dut/FSM/Rdest_mux_sel
add wave sim:/tb_arithmetic_comp/dut/FSM/Rsrc_mux_sel
add wave sim:/tb_arithmetic_comp/dut/FSM/Reg_File_En
add wave sim:/tb_arithmetic_comp/dut/Flags
add wave -divider "Registers"
add wave sim:/tb_arithmetic_comp/dut/DP/r0
add wave sim:/tb_arithmetic_comp/dut/DP/r1
add wave sim:/tb_arithmetic_comp/dut/DP/r2
add wave sim:/tb_arithmetic_comp/dut/DP/r3
add wave sim:/tb_arithmetic_comp/dut/DP/r4
add wave sim:/tb_arithmetic_comp/dut/DP/r6
add wave sim:/tb_arithmetic_comp/dut/DP/r7
add wave sim:/tb_arithmetic_comp/dut/DP/r8
add wave sim:/tb_arithmetic_comp/dut/DP/r9
add wave sim:/tb_arithmetic_comp/dut/DP/r10
add wave sim:/tb_arithmetic_comp/dut/DP/r11
add wave sim:/tb_arithmetic_comp/dut/DP/r12
add wave sim:/tb_arithmetic_comp/dut/DP/r15

run 300ns
*/



