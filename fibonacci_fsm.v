module fibonacci_fsm (
	input wire clk,
	input wire reset,
	input wire [4:0] Flags_out,
	
	output reg [15:0] wEnable,
	output reg [15:0] Imm_in,
	output reg [7:0] opcode,
	output reg [3:0] Rdest_sel,
	output reg [3:0] Rsrc_sel,
	output reg Imm_sel
);

	// STATE ENCODING
	localparam RESET = 4'd0;
	localparam INIT_B = 4'd1;
	localparam INIT_N = 4'd2;
	localparam CHECK = 4'd3;
	localparam ADD_AB = 4'd4;
	localparam MOVE_A = 4'd5;
	localparam MOVE_B = 4'd6;
	localparam INC_I = 4'd7;
	localparam WRITE_OUT = 4'd8;
	localparam DONE = 4'd9;
	
	// state registers (present state, next state)
	reg [3:0] PS, NS;
	
	// ALU opcodes
	localparam [7:0] ADDU = 8'b0000_0110;
	localparam [7:0] ADDUI = 8'b0110_0000;
	localparam [7:0] CMP = 8'b0000_1011;
	localparam [7:0] NOP = 8'b0000_0000;
	
	localparam [15:0] N_VALUE = 16'd10;
	
	// Update state registers on every clock cycle
	always @(posedge clk or negedge reset) begin
		if (!reset) // check for reset button
			PS <= RESET;
		else
			PS <= NS;
	end
	
	// Logic for the next state
	always @(*) begin
		NS = PS;
		case (PS)
			RESET:
				NS = INIT_B;
			INIT_B:
				NS = INIT_N;
			INIT_N:
				NS = CHECK;
			
			CHECK: begin
				if (Flags_out[4])
					NS = ADD_AB;
				else
					NS = DONE;
			end
			
			ADD_AB:
				NS = MOVE_A;
			MOVE_A:
				NS = MOVE_B;
			MOVE_B:
				NS = INC_I;
			INC_I:
				NS = WRITE_OUT;
			WRITE_OUT:
				NS = CHECK;
			
			DONE:
				NS = DONE;
			default:
				NS = RESET;
		endcase
	end
	
	// Control logic
	always @(*) begin
		// initialize output values
		wEnable = 16'b0;
		Imm_in = 16'h0000;
		opcode = NOP; // waiting
		Rdest_sel = 4'd0;
		Rsrc_sel = 4'd0;
		Imm_sel = 1'b1;
		
		// do some logic based on the present state
		case (PS)
			// set b = 1
			INIT_B: begin
				opcode = ADDUI; 
				Rdest_sel = 4'd1; // r1 (from datapath)
				Imm_in = 16'd1;
				Imm_sel = 1'b0; // using immediate
				wEnable = 16'b0000_0000_0000_0010;
			end
			
			// set N = N_VALUE (some hard coded value for demo)
			INIT_N: begin
				opcode = ADDUI;
				Rdest_sel = 4'd4; // r4 (from datapath)
				Imm_in = N_VALUE;
				Imm_sel = 1'b0;
				wEnable = 16'b0000_0000_0001_0000;
			end
			
			// compare i to N
			CHECK: begin
				opcode = CMP;
				Rdest_sel = 4'd3; // i
				Rsrc_sel = 4'd4; // N
				Imm_sel = 1'b1;
			end
			
			// compute a+b
			ADD_AB: begin
				opcode = ADDU;
				Rdest_sel = 4'd0; // a
				Rsrc_sel = 4'd1; // b
				wEnable = 16'b0000_0000_0000_0100; // r2
			end
			
			// move a to equal b
			MOVE_A: begin
				opcode = ADDUI;
				Rdest_sel = 4'd1;
				Imm_in = 16'd0;
				Imm_sel = 1'b0;
				wEnable = 16'b0000_0000_0000_0001; // r0
			end
			
			// move b to equal a+b
			MOVE_B: begin
				opcode = ADDUI;
				Rdest_sel = 4'd2;
				Imm_in = 16'd0;
				Imm_sel = 1'b0;
				wEnable = 16'b0000_0000_0000_0010; // r1
			end
			
			// increase i (loop counter)
			INC_I: begin
				opcode = ADDUI;
				Rdest_sel = 4'd3;
				Imm_in = 16'd1;
				Imm_sel = 1'b0;
				wEnable = 16'b0000_0000_0000_1000;
			end
			
			// set the output = b
			WRITE_OUT: begin
				opcode = ADDUI;
				Rdest_sel = 4'd1;
				Imm_in = 16'd0;
				Imm_sel = 1'b0;
				wEnable = 16'b0000_0000_0010_0000; // r5
			end
			
			DONE: begin
				opcode = NOP;
			end
		endcase
	end
	
endmodule
					