`timescale 1ns / 1ps

module bram_FSM_TOP_TB;

    // Clock + reset
    reg Clk;
    reg Rst;

    // Optional debug outputs (match your top)
    wire [15:0] bram_output;

    // Instantiate DUT
    bram_FSM_TOP DUT (
        .Clk(Clk),
        .Rst(Rst),
        .bram_output(bram_output)
    );

    // Clock generation: 100 MHz
    initial begin
        Clk = 0;
        forever #5 Clk = ~Clk;
    end

    // Test sequence
    initial begin
        // Dump waves
        $dumpfile("bram_fsm.vcd");
        $dumpvars(0, tb_bram_FSM_TOP);

        // Reset
        Rst = 1;
        #20;
        Rst = 0;

        // Let FSM run
        #2000;

        // Final observation
        $display("FINAL bram_output = %h", bram_output);

        $finish;
    end

endmodule
