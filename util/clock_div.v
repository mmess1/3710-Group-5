module clock_div #(parameter integer DIV = 3_000_000) (
    input  wire clk_in,
    input  wire reset,
    output reg  clk_out
);
    // Integer for counting cycles
    reg [31:0] cnt; // Ensure this is a register

    always @(posedge clk_in or negedge reset) begin
        if (!reset) begin
            cnt     <= 0;         // Reset the counter to 0
            clk_out <= 1'b0;      // Reset the output clock to 0
        end else begin
            if (cnt == DIV - 1) begin
                cnt     <= 0;           // Reset counter when it reaches DIV-1
                clk_out <= ~clk_out;    // Toggle clock output
            end else begin
                cnt <= cnt + 1;         // Increment counter
            end
        end
    end
endmodule
