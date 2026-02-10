module instr_buffer(
    input wire clk,         // Clock signal
    input wire reset,       // Reset signal
    input wire load_en,        // Control signal to load data --> from sfm
    input wire [15:0] in,   // 16-bit input instruction
    output reg [15:0] out   // 16-bit output instruction
);
    
    // On reset, clear the output. Otherwise, load data on load signal.
    always @(posedge clk or negedge reset) begin
        if (!reset) begin
            out <= 16'b0;  // Clear the instruction on reset
        end else if (load_en) begin
            out <= in;     // Load new instruction into register
        end
    end

endmodule
