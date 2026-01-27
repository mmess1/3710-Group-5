`timescale 1ns / 1ps

module tb_fibonacci_fsm;

    // Inputs
    reg clk;
    reg reset;
    reg [4:0] Flags_out;

    // Outputs
    wire [15:0] wEnable;
    wire [15:0] Imm_in;
    wire [7:0]  opcode;
    wire [3:0]  Rdest_sel;
    wire [3:0]  Rsrc_sel;
    wire        Imm_sel;

    // Instantiate the DUT (Device Under Test)
    fibonacci_fsm dut (
        .clk(clk),
        .reset(reset),
        .Flags_out(Flags_out),
        .wEnable(wEnable),
        .Imm_in(Imm_in),
        .opcode(opcode),
        .Rdest_sel(Rdest_sel),
        .Rsrc_sel(Rsrc_sel),
        .Imm_sel(Imm_sel)
    );

    // Clock generation: 10 ns period
    always #5 clk = ~clk;

    initial begin
        // Initial values
        clk = 0;
        reset = 1;
        Flags_out = 5'b00000;

        // Hold reset for a couple cycles
        #20;
        reset = 0;

        // ---- Simulate CMP result ----
        // Flags_out[4] is used in CHECK state
        // 1 = keep looping
        // 0 = exit to DONE

        // Let it loop a few times
        #40  Flags_out[4] = 1'b1;
        #40  Flags_out[4] = 1'b1;
        #40  Flags_out[4] = 1'b1;

        // Stop looping → DONE
        #40  Flags_out[4] = 1'b0;

        // Run a bit longer to observe DONE
        #40;

        $stop;
    end

endmodule
