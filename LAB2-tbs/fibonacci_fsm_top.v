
module fibonacci_fsm_top (
    input  wire CLOCK_50,
	 
	 input  wire [3:0]  KEY,
    output wire [9:0]  LEDR,
	 
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3
);

    wire Rst = KEY[0];

    wire [3:0]  Rsrc_mux_sel;
    wire [3:0]  Rdest_mux_sel;
    wire        Imm_mux_sel;
    wire [15:0] Imm_val;
    wire [7:0]  Opcode;
    wire [15:0] Reg_File_En;
	 
	wire [15:0] r5;
   wire [4:0]  Flags;
	
	//clock div
	 wire clk_slow;

    clock_divider #(.DIV(5_000_000)) u_div (
        .clk_in (CLOCK_50),
        .reset  (Rst),
        .clk_out(clk_slow)
    );
	 
	 

    fibonacci_fsm fibfsm (
        .clk(clk_slow),
        .reset(Rst),
        .Flags_out(Flags),

        .Rsrc_sel(Rsrc_mux_sel),
        .Rdest_sel(Rdest_mux_sel),
        .Imm_sel(Imm_mux_sel),
        .Imm_in(Imm_val),
        .opcode(Opcode),
        .wEnable(Reg_File_En)
    );
	 
    data_path dap (
        .clk(clk_slow),
        .reset(Rst),

        .wEnable(Reg_File_En),
        .Imm_in(Imm_val),
        .opcode(Opcode),

        .Rdest_select(Rdest_mux_sel),
        .Rsrc_select(Rsrc_mux_sel),
        .Imm_select(Imm_mux_sel),
		  .r5(r5),

        .Flags_out(Flags)
    );
		 
		 function [6:0] hex7;
        input [3:0] x;
        begin
            case (x)
                4'h0: hex7 = 7'b1000000;
                4'h1: hex7 = 7'b1111001;
                4'h2: hex7 = 7'b0100100;
                4'h3: hex7 = 7'b0110000;
                4'h4: hex7 = 7'b0011001;
                4'h5: hex7 = 7'b0010010;
                4'h6: hex7 = 7'b0000010;
                4'h7: hex7 = 7'b1111000;
                4'h8: hex7 = 7'b0000000;
                4'h9: hex7 = 7'b0010000;
                4'hA: hex7 = 7'b0001000;
                4'hB: hex7 = 7'b0000011;
                4'hC: hex7 = 7'b1000110;
                4'hD: hex7 = 7'b0100001;
                4'hE: hex7 = 7'b0000110;
                4'hF: hex7 = 7'b0001110;
                default: hex7 = 7'b1111111;
            endcase
        end
    endfunction
	 
    assign HEX0 = hex7(r5[3:0]);
    assign HEX1 = hex7(r5[7:4]);
    assign HEX2 = hex7(r5[11:8]);
    assign HEX3 = hex7(r5[15:12]);
	 
		 
endmodule

module clock_divider #(parameter integer DIV = 3_000_000) (
    input  wire clk_in,
    input  wire reset,
    output reg  clk_out
);
    integer cnt;

    always @(posedge clk_in or negedge reset) begin
        if (!reset) begin
            cnt     <= 0;
            clk_out <= 1'b0;
        end else begin
            if (cnt == DIV-1) begin
                cnt     <= 0;
                clk_out <= ~clk_out;
            end else begin
                cnt <= cnt + 1;
            end
        end
    end
endmodule
