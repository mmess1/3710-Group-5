
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:24:24 09/13/2015 
// Design Name: 
// Module Name:    regbank 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module Register (
   	 input [15:0] Result,
	 input w_Enable, reset, clk,
	 output reg [15:0] r
);
	 
 always @( posedge clk or negedge reset) begin
	if (!reset) r <= 16'h0000;
	else
		begin			
			if (w_Enable)
				begin
					r <= Result;
				end
			else
				begin
					r <= r;
				end
		end
	end
endmodule


// Shown below is one way to implement the register file
// This is a bottom-up, structural instantiation
// Another module is described in another file...
// .... which shows two dimensional construct for regfile

// Structural Implementation of RegBank
/********/
module RegBank(
    input [15:0] ALUBus,       // Data to write to register
    input [3:0] wEnable,         // 4-bit destination register index
    input clk, reset,          // Clock and Reset
    output [15:0] r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, r13, r14, r15 // All register outputs
);

    // Register Instantiations
    Register Inst0(.Result(ALUBus), .w_Enable(regEnable[0]), .reset(reset), .clk(clk), .r(r0));
    Register Inst1(.Result(ALUBus), .w_Enable(regEnable[1]), .reset(reset), .clk(clk), .r(r1));
    Register Inst2(.Result(ALUBus), .w_Enable(regEnable[2]), .reset(reset), .clk(clk), .r(r2));
    Register Inst3(.Result(ALUBus), .w_Enable(regEnable[3]), .reset(reset), .clk(clk), .r(r3));
    Register Inst4(.Result(ALUBus), .w_Enable(regEnable[4]), .reset(reset), .clk(clk), .r(r4));
    Register Inst5(.Result(ALUBus), .w_Enable(regEnable[5]), .reset(reset), .clk(clk), .r(r5));
    Register Inst6(.Result(ALUBus), .w_Enable(regEnable[6]), .reset(reset), .clk(clk), .r(r6));
    Register Inst7(.Result(ALUBus), .w_Enable(regEnable[7]), .reset(reset), .clk(clk), .r(r7));
    Register Inst8(.Result(ALUBus), .w_Enable(regEnable[8]), .reset(reset), .clk(clk), .r(r8));
    Register Inst9(.Result(ALUBus), .w_Enable(regEnable[9]), .reset(reset), .clk(clk), .r(r9));
    Register Inst10(.Result(ALUBus), .w_Enable(regEnable[10]), .reset(reset), .clk(clk), .r(r10));
    Register Inst11(.Result(ALUBus), .w_Enable(regEnable[11]), .reset(reset), .clk(clk), .r(r11));
    Register Inst12(.Result(ALUBus), .w_Enable(regEnable[12]), .reset(reset), .clk(clk), .r(r12));
    Register Inst13(.Result(ALUBus), .w_Enable(regEnable[13]), .reset(reset), .clk(clk), .r(r13));
    Register Inst14(.Result(ALUBus), .w_Enable(regEnable[14]), .reset(reset), .clk(clk), .r(r14));
    Register Inst15(.Result(ALUBus), .w_Enable(regEnable[15]), .reset(reset), .clk(clk), .r(r15));

    // Generate the regEnable signal: only one bit should be high
    reg [15:0] regEnable;

    always @(*) begin
        regEnable = 16'b0;  // Default to all bits off
        regEnable[rdest] = 1; // Set the rdest bit high (only one bit should be set)
    end

endmodule
