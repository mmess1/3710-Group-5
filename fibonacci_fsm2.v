module fibonacci_fsm (
    input  wire        clk,
    input  wire        reset,
    input  wire        step_pulse,
    input  wire [4:0]  Flags_out,

    output reg  [15:0] wEnable,
    output reg  [15:0] Imm_in,
    output reg  [7:0]  opcode,
    output reg  [3:0]  Rdest_sel,
    output reg  [3:0]  Rsrc_sel,
    output reg         Imm_sel
);

    localparam RESET_S    = 4'd0;
    localparam INIT_B     = 4'd1;
    localparam INIT_I     = 4'd2;
    localparam INIT_N     = 4'd3;
    localparam WRITE_OUT0 = 4'd4;
    localparam WAIT_STEP  = 4'd5;
    localparam CHECK      = 4'd6;
    localparam ADD_AB     = 4'd7;
    localparam MOVE_A     = 4'd8;
    localparam MOVE_B     = 4'd9;
    localparam INC_I      = 4'd10;
    localparam WRITE_OUT  = 4'd11;
    localparam DONE       = 4'd12;

    reg [3:0] PS, NS;

    localparam [7:0] ADDU  = 8'b0000_0110;
    localparam [7:0] ADDUI = 8'b0110_0000;
    localparam [7:0] CMP   = 8'b0000_1011;
    localparam [7:0] NOP   = 8'b0000_0000;

    localparam [15:0] N_VALUE = 16'd10;

    always @(posedge clk) begin
        if (reset) PS <= RESET_S;
        else       PS <= NS;
    end

    always @(*) begin
        NS = PS;
        case (PS)
            RESET_S:    NS = INIT_B;
            INIT_B:     NS = INIT_I;
            INIT_I:     NS = INIT_N;
            INIT_N:     NS = WRITE_OUT0;
            WRITE_OUT0: NS = WAIT_STEP;

            WAIT_STEP: begin
                if (step_pulse) NS = CHECK;
                else            NS = WAIT_STEP;
            end

            // Flags_out[4] is used as "less-than" from CMP (i < N)
            CHECK: begin
                if (Flags_out[4]) NS = ADD_AB;
                else              NS = DONE;
            end

            ADD_AB:     NS = MOVE_A;
            MOVE_A:     NS = MOVE_B;
            MOVE_B:     NS = INC_I;
            INC_I:      NS = WRITE_OUT;
            WRITE_OUT:  NS = WAIT_STEP;

            DONE:       NS = DONE;

            default:    NS = RESET_S;
        endcase
    end

    always @(*) begin
        wEnable   = 16'b0;
        Imm_in    = 16'h0000;
        opcode    = NOP;
        Rdest_sel = 4'd0;
        Rsrc_sel  = 4'd0;
        Imm_sel   = 1'b1;

        case (PS)
            INIT_B: begin
                // R1 = 1  (assumes regfile resets to 0)
                opcode    = ADDUI;
                Rdest_sel = 4'd1;         // A = R1
                Imm_in    = 16'd1;        // +1
                Imm_sel   = 1'b0;         // use immediate
                wEnable   = 16'b0000_0000_0000_0010; // write R1
            end

            INIT_I: begin
                // R3 = 0  (assumes regfile resets to 0)
                opcode    = ADDUI;
                Rdest_sel = 4'd3;         // A = R3
                Imm_in    = 16'd0;        // +0
                Imm_sel   = 1'b0;
                wEnable   = 16'b0000_0000_0000_1000; // write R3
            end

            INIT_N: begin
                // R4 = N_VALUE  (assumes regfile resets to 0)
                opcode    = ADDUI;
                Rdest_sel = 4'd4;         // A = R4
                Imm_in    = N_VALUE;
                Imm_sel   = 1'b0;
                wEnable   = 16'b0000_0000_0001_0000; // write R4
            end

            CHECK: begin
                // CMP R3 (i) vs R4 (N)
                opcode    = CMP;
                Rdest_sel = 4'd3;         // i
                Rsrc_sel  = 4'd4;         // N
                Imm_sel   = 1'b1;
            end

            ADD_AB: begin
                // R2 = R0 (a) + R1 (b)
                opcode    = ADDU;
                Rdest_sel = 4'd0;         // a
                Rsrc_sel  = 4'd1;         // b
                Imm_sel   = 1'b1;
                wEnable   = 16'b0000_0000_0000_0100; // write R2
            end

            MOVE_A: begin
                // R0 = R1 (a = b) using +0
                opcode    = ADDUI;
                Rdest_sel = 4'd1;         // A = R1
                Imm_in    = 16'd0;
                Imm_sel   = 1'b0;
                wEnable   = 16'b0000_0000_0000_0001; // write R0
            end

            MOVE_B: begin
                // R1 = R2 (b = a+b) using +0
                opcode    = ADDUI;
                Rdest_sel = 4'd2;         // A = R2
                Imm_in    = 16'd0;
                Imm_sel   = 1'b0;
                wEnable   = 16'b0000_0000_0000_0010; // write R1
            end

            INC_I: begin
                // R3 = R3 + 1
                opcode    = ADDUI;
                Rdest_sel = 4'd3;         // A = R3
                Imm_in    = 16'd1;
                Imm_sel   = 1'b0;
                wEnable   = 16'b0000_0000_0000_1000; // write R3
            end

            WRITE_OUT0: begin
                // R5 = R1 (initial output = b)
                opcode    = ADDUI;
                Rdest_sel = 4'd1;         // A = R1
                Imm_in    = 16'd0;
                Imm_sel   = 1'b0;
                wEnable   = 16'b0000_0000_0010_0000; // write R5
            end

            WRITE_OUT: begin
                // R5 = R1 (output = b)
                opcode    = ADDUI;
                Rdest_sel = 4'd1;         // A = R1
                Imm_in    = 16'd0;
                Imm_sel   = 1'b0;
                wEnable   = 16'b0000_0000_0010_0000; // write R5
            end

            WAIT_STEP: begin
                opcode = NOP;
            end

            DONE: begin
                opcode = NOP;
            end

            default: begin
                opcode = NOP;
            end
        endcase
    end

endmodule
