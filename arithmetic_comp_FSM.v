module Shift_Add_Acc_FSM #(
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
    localparam s_set_multiplicand = 4'd1; 
    localparam s_set_multiplier = 4'd2;
    localparam s_check_multiplier = 4'd3;
    localparam s_get_lsb = 4'd4;
    localparam s_check_lsb = 4'd5;
    localparam s_add_acc = 4'd6;
    localparam s_shift_multiplicand = 4'd7;
    localparam s_shift_multiplier = 4'd8;
    localparam s_final = 4'd9;

    reg [3:0] PS; // Present State
    reg [3:0] NS; // Next State

    localparam ADD   = 8'b0000_0101;
    localparam ADDI  = 8'b0101_xxxx;
    localparam ADDU  = 8'b0000_0110;
    localparam ADDUI = 8'b0110_xxxx;
    localparam ADDC  = 8'b0000_0111;
    localparam ADDCI = 8'b0111_xxxx;
    localparam SUB   = 8'b0000_1001;
    localparam SUBI  = 8'b1001_xxxx;
    localparam CMP   = 8'b0000_1011;
    localparam CMPI  = 8'b1011_xxxx;
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
    localparam NOP   = 8'b0000_0000;


    // Init PS to the inital state or next state
	always@(posedge Clk, negedge Rst) begin
		if(~Rst)
			PS <= s_init;
		else
			PS <= NS;
	end

    // Set Next State
	always@(PS) begin
		case(PS)
            s_init: begin
               NS = s_set_multiplicand; 
            end
            s_set_multiplicand: begin
                NS = s_set_multiplier;
            end
            s_set_multiplier: begin
                NS = s_check_multiplier;
            end
            s_check_multiplier: begin
                if (~Flags[3]) begin
                    NS = s_get_lsb;
                end
                else begin
                    NS = s_final;
                end
            end
            s_get_lsb: begin
                NS = s_check_lsb;
            end
            s_check_lsb: begin
                if (~Flags[3]) begin
                    NS = s_add_acc;
                end
                else begin
                    NS = s_shift_multiplicand;
                end
            end
            s_add_acc: begin
                NS = s_shift_multiplicand;
            end
            s_shift_multiplicand: begin
                NS = s_shift_multiplier;
            end
            s_shift_multiplier: begin
                NS = s_check_multiplier;
            end
            s_final: begin
                NS = s_final;
            end
			default: NS = s_init;
		endcase
	end
	
    // Set Outputs
	always@(PS)begin
        Rsrc_mux_sel  =  4'dx; 
        Rdest_mux_sel =  4'dx; 
        Imm_mux_sel   =  1'bx;
        Imm_val       = 16'bx;
        Opcode        =  8'bx; 
        Reg_File_En   = 16'bx;

		case(PS)
            s_init: begin
                Rsrc_mux_sel  =  4'dx; 
                Rdest_mux_sel =  4'dx; 
                Imm_mux_sel   =  1'bx;
                Imm_val       = 16'dx;
                Opcode        =  8'bx; 
                Reg_File_En   = 16'dx;
            end
            s_set_multiplicand: begin
                Rsrc_mux_sel  =   4'd0; 
                Rdest_mux_sel =   4'd0; 
                Imm_mux_sel   =   1'b1;

                // 1st Test Values
                // Imm_val       = 16'd11;
                
                // 2nd Test Values
                // Imm_val       = 16'd8;
                
                // 3rd Test Values
                // Imm_val       = 16'd7;

                // Waveform Screenshot values
                Imm_val       = 16'd6;
                
                Opcode        =  ADDUI; 
                Reg_File_En   =  16'b0000000000000001;
            end
            s_set_multiplier: begin
                Rsrc_mux_sel  =   4'd1; 
                Rdest_mux_sel =   4'd1; 
                Imm_mux_sel   =   1'b1;

                // 1st Test Values
                //Imm_val       =  16'd8;
                
                // 2nd Test Values
                // Imm_val       =  16'd7;

                // 3rd Test Values
                // Imm_val       =  16'd40;

                // Waveform Screenshot values
                Imm_val       =  16'd5;

                Opcode        =  ADDUI; 
                Reg_File_En   =  16'b0000000000000010;
            end
            s_check_multiplier: begin
                Rsrc_mux_sel  =  4'dx; 
                Rdest_mux_sel =  4'd1; 
                Imm_mux_sel   =  1'b1;
                Imm_val       = 16'd0;
                Opcode        =  CMPI; 
                Reg_File_En   = 16'bx;
            end
            s_get_lsb: begin
                Rsrc_mux_sel  =  4'dx; 
                Rdest_mux_sel =  4'd1; 
                Imm_mux_sel   =  1'b1;
                Imm_val       = 16'd1;
                Opcode        =   AND; 
                Reg_File_En   = 16'dx;
            end
            s_check_lsb: begin
                Rsrc_mux_sel  =  4'dx; 
                Rdest_mux_sel =  4'dx; 
                Imm_mux_sel   =  1'bx;
                Imm_val       = 16'dx;
                Opcode        =   NOP; 
                Reg_File_En   = 16'dx;
            end
            s_add_acc: begin
                Rsrc_mux_sel  =  4'd0; 
                Rdest_mux_sel =  4'd2; 
                Imm_mux_sel   =  1'b0;
                Imm_val       = 16'dx;
                Opcode        =  ADDU; 
                Reg_File_En   = 16'b0000000000000100;
            end
            s_shift_multiplicand: begin
                Rsrc_mux_sel  =  4'dx; 
                Rdest_mux_sel =  4'd0; 
                Imm_mux_sel   =  1'b1;
                Imm_val       = 16'd1;
                Opcode        =  LSHI; 
                Reg_File_En   = 16'b0000000000000001;
            end
            s_shift_multiplier: begin
                Rsrc_mux_sel  =  4'dx; 
                Rdest_mux_sel =  4'd1; 
                Imm_mux_sel   =  1'b1;
                Imm_val       = 16'd1;
                Opcode        =  RSHI; 
                Reg_File_En   = 16'b0000000000000010;
            end
            s_final: begin
                Rsrc_mux_sel  =  4'dx; 
                Rdest_mux_sel =  4'dx; 
                Imm_mux_sel   =  1'bx;
                Imm_val       = 16'dx;
                Opcode        =   NOP; 
                Reg_File_En   = 16'dx;
            end
		endcase
	end
endmodule