module instr_buffer(
    input wire clk,
    input wire reset,
    input wire load_en,
    input wire [15:0] in,
    output reg [15:0] out
);

    always @(posedge clk or negedge reset) begin
        if (!reset)
            out <= 16'b0;
        else if (load_en)
            out <= in;
    end

endmodule
