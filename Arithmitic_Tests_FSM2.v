module Arithmitic_Tests_FSM2 #(
    parameter BIT_WIDTH    = 16,
    parameter OPCODE_WIDTH = 8,
    parameter FLAG_WIDTH   = 5,
    parameter SEL_WIDTH    = 4
)(
    input  wire                    Clk,
    input  wire                    Rst,
    input  wire [FLAG_WIDTH-1:0]   Flags,

    output reg  [SEL_WIDTH-1:0]    Rsrc_mux_sel,
    output reg  [SEL_WIDTH-1:0]    Rdest_mux_sel,
    output reg                     Imm_mux_sel,
    output reg  [BIT_WIDTH-1:0]    Imm_val,
    output reg  [OPCODE_WIDTH-1:0] Opcode,
    output reg  [15:0]             Reg_File_En
);

    // Flags: [4]=L, [3]=C, [2]=F, [1]=Z, [0]=N

    localparam [7:0] WAIT  = 8'b0000_0000;

    localparam [7:0] ADD   = 8'b0000_0001;
    localparam [7:0] ADDU  = 8'b0000_0010;

    localparam [7:0] ADDI  = 8'b0101_0000;
    localparam [7:0] ADDUI = 8'b0110_0000;
    localparam [7:0] ADDC  = 8'b0000_0111;
    localparam [7:0] ADDCI = 8'b0111_0000;

    localparam [7:0] SUBC  = 8'b0000_1010;
    localparam [7:0] SUBCI = 8'b1010_0000;

    localparam [7:0] MOV   = 8'b0000_1101;
    localparam [7:0] MOVI  = 8'b1101_0000;

    localparam [7:0] MUL   = 8'b0000_1110;
    localparam [7:0] MULI  = 8'b1110_0000;

    localparam [7:0] CMP   = 8'b0000_1011;
    localparam [7:0] CMPI  = 8'b1011_0000;

    localparam [7:0] LSH   = 8'b0000_1100;
    localparam [7:0] LSHI  = 8'b1100_0000;

    localparam [7:0] RSHI  = 8'b1000_0000;
    localparam [7:0] ARSHI = 8'b1111_0000;

    localparam [5:0]
        s_init          = 6'd0,

        s_load_r0       = 6'd1,
        s_load_r1       = 6'd2,

        s_addi_r2       = 6'd3,
        s_chk_r2        = 6'd4,

        s_load_r6       = 6'd5,
        s_addui_r3      = 6'd6,
        s_chk_r3        = 6'd7,

        s_addc_r4       = 6'd8,
        s_chk_r4        = 6'd9,

        s_addci_r5      = 6'd10,
        s_chk_r5        = 6'd11,

        s_subc_r7       = 6'd12,
        s_chk_r7        = 6'd13,

        s_subci_r8      = 6'd14,
        s_chk_r8        = 6'd15,

        s_mov_r9        = 6'd16,
        s_chk_r9        = 6'd17,

        s_mul_r10       = 6'd18,
        s_chk_r10       = 6'd19,

        s_muli_r11      = 6'd20,
        s_chk_r11       = 6'd21,

        s_lsh_r12       = 6'd22,
        s_chk_r12       = 6'd23,

        s_lshi_r13      = 6'd24,
        s_chk_r13       = 6'd25,

        s_load_r14      = 6'd26,
        s_rshi_r6       = 6'd27,
        s_chk_r6        = 6'd28,

        s_arshi_r7      = 6'd29,
        s_chk_r7b       = 6'd30,

        // Flag tests (C, F, N vs L)
        s_load_c_r0     = 6'd31,  // R0=FFFF
        s_load_c_r1     = 6'd32,  // R1=0001
        s_addu_c        = 6'd33,  // R2=R0+R1 (ADDU)
        s_chk_addu_cf   = 6'd34,  // expect C=1, Z=1, N=0
        s_chk_addu_res  = 6'd35,  // CMPI R2,0

        s_load_f_r0     = 6'd36,  // R0=7FFF
        s_load_f_r1     = 6'd37,  // R1=0001
        s_add_f         = 6'd38,  // R3=R0+R1 (ADD signed)
        s_chk_add_ff    = 6'd39,  // expect F=1, N=1, Z=0
        s_chk_add_res   = 6'd40,  // CMPI R3,8000

        s_load_nl_r0    = 6'd41,  // R0=FFFF (-1 signed)
        s_load_nl_r1    = 6'd42,  // R1=0001
        s_cmp_nl        = 6'd43,  // CMP R0,R1
        s_chk_cmp_nl    = 6'd44,  // expect N=1, L=0, Z=0

        s_pass          = 6'd45,
        s_fail          = 6'd46,
        s_final         = 6'd47;

    reg [5:0] PS, NS;

    always @(posedge Clk or posedge Rst) begin
        if (Rst) PS <= s_init;
        else     PS <= NS;
    end

    always @(*) begin
        NS = PS;
        case (PS)
            s_init:         NS = s_load_r0;
            s_load_r0:      NS = s_load_r1;
            s_load_r1:      NS = s_addi_r2;

            s_addi_r2:      NS = s_chk_r2;
            s_chk_r2:       NS = (Flags[1] ? s_load_r6 : s_fail);

            s_load_r6:      NS = s_addui_r3;
            s_addui_r3:     NS = s_chk_r3;
            s_chk_r3:       NS = (Flags[1] ? s_addc_r4 : s_fail);

            s_addc_r4:      NS = s_chk_r4;
            s_chk_r4:       NS = (Flags[1] ? s_addci_r5 : s_fail);

            s_addci_r5:     NS = s_chk_r5;
            s_chk_r5:       NS = (Flags[1] ? s_subc_r7 : s_fail);

            s_subc_r7:      NS = s_chk_r7;
            s_chk_r7:       NS = (Flags[1] ? s_subci_r8 : s_fail);

            s_subci_r8:     NS = s_chk_r8;
            s_chk_r8:       NS = (Flags[1] ? s_mov_r9 : s_fail);

            s_mov_r9:       NS = s_chk_r9;
            s_chk_r9:       NS = (Flags[1] ? s_mul_r10 : s_fail);

            s_mul_r10:      NS = s_chk_r10;
            s_chk_r10:      NS = (Flags[1] ? s_muli_r11 : s_fail);

            s_muli_r11:     NS = s_chk_r11;
            s_chk_r11:      NS = (Flags[1] ? s_lsh_r12 : s_fail);

            s_lsh_r12:      NS = s_chk_r12;
            s_chk_r12:      NS = (Flags[1] ? s_lshi_r13 : s_fail);

            s_lshi_r13:     NS = s_chk_r13;
            s_chk_r13:      NS = (Flags[1] ? s_load_r14 : s_fail);

            s_load_r14:     NS = s_rshi_r6;
            s_rshi_r6:      NS = s_chk_r6;
            s_chk_r6:       NS = (Flags[1] ? s_arshi_r7 : s_fail);

            s_arshi_r7:     NS = s_chk_r7b;
            s_chk_r7b:      NS = (Flags[1] ? s_load_c_r0 : s_fail);

            s_load_c_r0:    NS = s_load_c_r1;
            s_load_c_r1:    NS = s_addu_c;
            s_addu_c:       NS = s_chk_addu_cf;
            s_chk_addu_cf:  NS = ((Flags[3] && Flags[1] && !Flags[0]) ? s_chk_addu_res : s_fail);
            s_chk_addu_res: NS = (Flags[1] ? s_load_f_r0 : s_fail);

            s_load_f_r0:    NS = s_load_f_r1;
            s_load_f_r1:    NS = s_add_f;
            s_add_f:        NS = s_chk_add_ff;
            s_chk_add_ff:   NS = ((Flags[2] && Flags[0] && !Flags[1]) ? s_chk_add_res : s_fail);
            s_chk_add_res:  NS = (Flags[1] ? s_load_nl_r0 : s_fail);

            s_load_nl_r0:   NS = s_load_nl_r1;
            s_load_nl_r1:   NS = s_cmp_nl;
            s_cmp_nl:       NS = s_chk_cmp_nl;
            s_chk_cmp_nl:   NS = ((Flags[0] && !Flags[4] && !Flags[1]) ? s_pass : s_fail);

            s_pass:         NS = s_final;
            s_fail:         NS = s_final;
            s_final:        NS = s_final;

            default:        NS = s_init;
        endcase
    end

    always @(*) begin
        Rsrc_mux_sel  = 4'd0;
        Rdest_mux_sel = 4'd0;
        Imm_mux_sel   = 1'b0;
        Imm_val       = 16'd0;
        Opcode        = WAIT;
        Reg_File_En   = 16'h0000;

        case (PS)

            s_load_r0: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'h0001;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0001;
            end

            s_load_r1: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'h0002;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0010;
            end

            s_addi_r2: begin
                Rdest_mux_sel = 4'd0;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0003;
                Opcode        = ADDI;
                Reg_File_En   = 16'b0000_0000_0000_0100;
            end
            s_chk_r2: begin
                Rdest_mux_sel = 4'd2;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0004;
                Opcode        = CMPI;
            end

            s_load_r6: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'hFFFF;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0100_0000;
            end

            s_addui_r3: begin
                Rdest_mux_sel = 4'd6;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0001;
                Opcode        = ADDUI;
                Reg_File_En   = 16'b0000_0000_0000_1000;
            end
            s_chk_r3: begin
                Rdest_mux_sel = 4'd3;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0000;
                Opcode        = CMPI;
            end

            s_addc_r4: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = ADDC;
                Reg_File_En   = 16'b0000_0000_0001_0000;
            end
            s_chk_r4: begin
                Rdest_mux_sel = 4'd4;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0003;
                Opcode        = CMPI;
            end

            s_addci_r5: begin
                Rdest_mux_sel = 4'd0;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0001;
                Opcode        = ADDCI;
                Reg_File_En   = 16'b0000_0000_0010_0000;
            end
            s_chk_r5: begin
                Rdest_mux_sel = 4'd5;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0002;
                Opcode        = CMPI;
            end

            s_subc_r7: begin
                Rdest_mux_sel = 4'd1;
                Rsrc_mux_sel  = 4'd0;
                Imm_mux_sel   = 1'b0;
                Opcode        = SUBC;
                Reg_File_En   = 16'b0000_0000_1000_0000;
            end
            s_chk_r7: begin
                Rdest_mux_sel = 4'd7;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0001;
                Opcode        = CMPI;
            end

            s_subci_r8: begin
                Rdest_mux_sel = 4'd0;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0001;
                Opcode        = SUBCI;
                Reg_File_En   = 16'b0000_0001_0000_0000;
            end
            s_chk_r8: begin
                Rdest_mux_sel = 4'd8;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0000;
                Opcode        = CMPI;
            end

            s_mov_r9: begin
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = MOV;
                Reg_File_En   = 16'b0000_0010_0000_0000;
            end
            s_chk_r9: begin
                Rdest_mux_sel = 4'd9;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0002;
                Opcode        = CMPI;
            end

            s_mul_r10: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = MUL;
                Reg_File_En   = 16'b0000_0100_0000_0000;
            end
            s_chk_r10: begin
                Rdest_mux_sel = 4'd10;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0002;
                Opcode        = CMPI;
            end

            s_muli_r11: begin
                Rdest_mux_sel = 4'd1;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0004;
                Opcode        = MULI;
                Reg_File_En   = 16'b0000_1000_0000_0000;
            end
            s_chk_r11: begin
                Rdest_mux_sel = 4'd11;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0008;
                Opcode        = CMPI;
            end

            s_lsh_r12: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd2;
                Imm_mux_sel   = 1'b0;
                Opcode        = LSH;
                Reg_File_En   = 16'b0001_0000_0000_0000;
            end
            s_chk_r12: begin
                Rdest_mux_sel = 4'd12;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0010;
                Opcode        = CMPI;
            end

            s_lshi_r13: begin
                Rdest_mux_sel = 4'd0;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0003;
                Opcode        = LSHI;
                Reg_File_En   = 16'b0010_0000_0000_0000;
            end
            s_chk_r13: begin
                Rdest_mux_sel = 4'd13;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0008;
                Opcode        = CMPI;
            end

            s_load_r14: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'h8000;
                Opcode      = MOVI;
                Reg_File_En = 16'b0100_0000_0000_0000;
            end

            s_rshi_r6: begin
                Rdest_mux_sel = 4'd14;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0001;
                Opcode        = RSHI;
                Reg_File_En   = 16'b0000_0000_0100_0000;
            end
            s_chk_r6: begin
                Rdest_mux_sel = 4'd6;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h4000;
                Opcode        = CMPI;
            end

            s_arshi_r7: begin
                Rdest_mux_sel = 4'd14;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0001;
                Opcode        = ARSHI;
                Reg_File_En   = 16'b0000_0000_1000_0000;
            end
            s_chk_r7b: begin
                Rdest_mux_sel = 4'd7;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'hC000;
                Opcode        = CMPI;
            end

            s_load_c_r0: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'hFFFF;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0001;
            end

            s_load_c_r1: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'h0001;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0010;
            end

            s_addu_c: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = ADDU;
                Reg_File_En   = 16'b0000_0000_0000_0100; // R2
            end

            // Hold ADDU inputs/opcode to check flags from ADDU
            s_chk_addu_cf: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = ADDU;
                Reg_File_En   = 16'h0000;
            end

            s_chk_addu_res: begin
                Rdest_mux_sel = 4'd2;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h0000;
                Opcode        = CMPI;
            end

            s_load_f_r0: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'h7FFF;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0001;
            end

            s_load_f_r1: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'h0001;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0010;
            end

            s_add_f: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = ADD;
                Reg_File_En   = 16'b0000_0000_0000_1000; // R3
            end

            // Hold ADD inputs/opcode to check flags from ADD
            s_chk_add_ff: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = ADD;
                Reg_File_En   = 16'h0000;
            end

            s_chk_add_res: begin
                Rdest_mux_sel = 4'd3;
                Imm_mux_sel   = 1'b1;
                Imm_val       = 16'h8000;
                Opcode        = CMPI;
            end

            s_load_nl_r0: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'hFFFF;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0001;
            end

            s_load_nl_r1: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'h0001;
                Opcode      = MOVI;
                Reg_File_En = 16'b0000_0000_0000_0010;
            end

            s_cmp_nl: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = CMP;
                Reg_File_En   = 16'h0000;
            end

            // Hold CMP inputs/opcode to check N vs L from CMP
            s_chk_cmp_nl: begin
                Rdest_mux_sel = 4'd0;
                Rsrc_mux_sel  = 4'd1;
                Imm_mux_sel   = 1'b0;
                Opcode        = CMP;
                Reg_File_En   = 16'h0000;
            end

            s_pass: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'h2222;
                Opcode      = MOVI;
                Reg_File_En = 16'b1000_0000_0000_0000;
            end

            s_fail: begin
                Imm_mux_sel = 1'b1;
                Imm_val     = 16'hDEAD;
                Opcode      = MOVI;
                Reg_File_En = 16'b1000_0000_0000_0000;
            end

            default: begin
                Opcode      = WAIT;
                Reg_File_En = 16'h0000;
            end
        endcase
    end

endmodule
