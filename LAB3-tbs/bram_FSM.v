module bram_FSM (
    input  wire         Clk,
    input  wire         Rst,
    input  wire [15:0]  q_a,
    input  wire [15:0]  q_b,

    output reg  [15:0]  data_a,
    output reg  [15:0]  data_b,
    output reg  [9:0]   addr_a,
    output reg  [9:0]   addr_b,
    output reg          we_a,
    output reg          we_b,
    output reg          en_a,
    output reg          en_b,

    output reg  [15:0]  bram_output
);

    localparam s_init  = 4'd0; // Initial state
    localparam s_read  = 4'd1; // read from block 0 at addr
    localparam s_write = 4'd2; // write q_a into block 1 at addr
    localparam s_final = 4'd3; // read block 1 and display (cycle)

    reg [3:0] PS; // Present State
    reg [3:0] NS; // Next State

    reg [8:0] fib;
    reg [8:0] fib_next;

    always @(posedge Clk, negedge Rst) begin
        if (~Rst) begin
            PS   <= s_init;
            fib <= 9'd0;
        end else begin
            PS   <= NS;
            fib <= fib_next;
        end
    end

    // Set Next State
    always @(*) begin
        NS        = PS;
        fib_next = fib;

        case (PS)
            s_init: begin
                NS        = s_read;
                fib_next = 9'd0;
            end

            s_read: begin
                NS = s_write;
            end

            s_write: begin
                NS        = (fib == 9'd11) ? s_final : s_read;
                fib_next = (fib == 9'd11) ? 9'd0 : (fib + 9'd1);
            end

            s_final: begin
                NS        = s_final;
                fib_next = (fib == 9'd11) ? 9'd0 : (fib + 9'd1);
            end

            default: begin
                NS        = s_init;
                fib_next = 9'd0;
            end
        endcase
    end

    // Set Outputs
    always @(*) begin
        data_a      = 16'd0;
        data_b      = 16'd0;
        addr_a      = 10'd0;
        addr_b      = 10'd0;
        we_a        = 1'b0;
        we_b        = 1'b0;
        en_a        = 1'b0;
        en_b        = 1'b0;
        bram_output = 16'd0;

        case (PS)
            s_init: begin
                bram_output = 16'd0;
            end

            s_read: begin
                en_a   = 1'b1;
                we_a   = 1'b0;
                addr_a = {1'b0, fib}; // block 0
            end

            s_write: begin
                en_b   = 1'b1;
                we_b   = 1'b1;
                addr_b = {1'b1, fib}; // block 1
                data_b = q_a;
            end

            s_final: begin
                en_a        = 1'b1;
                we_a        = 1'b0;
                addr_a      = {1'b1, fib}; // block 1
                bram_output = q_a;
            end
        endcase
    end

endmodule
