module pong_cpu_fsm (
    input wire clk,
    input wire reset,

    input  wire [15:0] instr_set,

    /* ALU */
    input  wire [4:0] Flags_in,

    /* Reg file */
    output reg  [15:0] wEnable,

    /* Decoder outputs to datapath */
    output wire [7:0]  opcode,
    output wire [3:0]  Rdest_select,
    output wire [3:0]  Rsrc_select,
    output wire [15:0] Imm_in,      
    output reg         Imm_select,

    /* RAM */
    output reg we_a, en_a, en_b, ram_wen,

    /* LS_cntr MUX */
    output reg lsc_mux_selct,

    /* PC */
    output reg [15:0] pc_add_k,
    output reg pc_mux_selct, pc_en,

    /* MUXs */
    output reg fsm_alu_mem_selct,

    output reg decoder_en,

    /* MMIO */
    input  wire is_mmio,
    output reg  mmio_we
);

localparam [15:0] ADD    = 16'b0000_xxxx_0101_xxxx;
localparam [15:0] ADDU   = 16'b0000_xxxx_0110_xxxx;
localparam [15:0] ADDC   = 16'b0000_xxxx_0111_xxxx;
localparam [15:0] ADDI   = 16'b0101_xxxx_xxxx_xxxx;
localparam [15:0] ADDUI  = 16'b0110_xxxx_xxxx_xxxx;
localparam [15:0] ADDCI  = 16'b0111_xxxx_xxxx_xxxx;
localparam [15:0] MOV    = 16'b0000_xxxx_1101_xxxx;
localparam [15:0] MOVI   = 16'b1101_xxxx_xxxx_xxxx;
localparam [15:0] MUL    = 16'b0000_xxxx_1110_xxxx;
localparam [15:0] MULI   = 16'b1110_xxxx_xxxx_xxxx;
localparam [15:0] SUB    = 16'b0000_xxxx_1001_xxxx;
localparam [15:0] SUBC   = 16'b0000_xxxx_1010_xxxx;
localparam [15:0] SUBI   = 16'b1001_xxxx_xxxx_xxxx;
localparam [15:0] SUBCI  = 16'b1010_xxxx_xxxx_xxxx;
localparam [15:0] CMP    = 16'b0000_xxxx_1011_xxxx;
localparam [15:0] CMPI   = 16'b1011_xxxx_xxxx_xxxx;
localparam [15:0] AND    = 16'b0000_xxxx_0001_xxxx;
localparam [15:0] OR     = 16'b0000_xxxx_0010_xxxx;
localparam [15:0] XOR    = 16'b0000_xxxx_0011_xxxx;
localparam [15:0] NOT    = 16'b0000_xxxx_0100_xxxx;
localparam [15:0] LSH    = 16'b1000_xxxx_1100_xxxx;
localparam [15:0] LSHI   = 16'b1000_xxxx_0000_xxxx;
localparam [15:0] RSH    = 16'b0000_xxxx_1000_xxxx;
localparam [15:0] RSHI   = 16'b1000_xxxx_1000_xxxx;
localparam [15:0] ARSH   = 16'b0000_xxxx_1111_xxxx;
localparam [15:0] ARSHI  = 16'b1111_xxxx_xxxx_xxxx;
localparam [15:0] WAIT   = 16'b0000_xxxx_0000_xxxx;
localparam [15:0] BRANCH = 16'b1100_xxxx_xxxx_xxxx;
localparam [15:0] LOAD   = 16'b0100_xxxx_0000_xxxx;
localparam [15:0] STOR   = 16'b0100_xxxx_0100_xxxx;

localparam [3:0] EQ = 4'b0000;
localparam [3:0] NE = 4'b0001;
localparam [3:0] GE = 4'b1101;
localparam [3:0] CS = 4'b0010;
localparam [3:0] CC = 4'b0011;
localparam [3:0] HI = 4'b0100;
localparam [3:0] LS = 4'b0101;
localparam [3:0] LO = 4'b1010;
localparam [3:0] HS = 4'b1011;
localparam [3:0] GT = 4'b0110;
localparam [3:0] LE = 4'b0111;
localparam [3:0] FS = 4'b1000;
localparam [3:0] FC = 4'b1001;
localparam [3:0] LT = 4'b1100;
localparam [3:0] UC = 4'b1110;
localparam [3:0] XX = 4'b1111;

localparam [2:0] S0_FETCH   = 3'd0;
localparam [2:0] S1_DECODE  = 3'd1;
localparam [2:0] S2_EXECUTE = 3'd2;
localparam [2:0] S3_STORE   = 3'd3;
localparam [2:0] S4_LOAD    = 3'd4;
localparam [2:0] S5_DOUT    = 3'd5;
localparam [2:0] S6_BRANCH  = 3'd6;

reg [2:0] PS, NS;
reg [4:0] saved_flags;

always @(posedge clk or negedge reset) begin
    if (!reset) PS <= S0_FETCH;
    else        PS <= NS;
end

always @(posedge clk or negedge reset) begin
    if (!reset)
        saved_flags <= 5'b0;
    else if ((PS == S2_EXECUTE) && ((opcode == 8'h0B) || (opcode == 8'hB0)))
        saved_flags <= Flags_in;
end

always @(*) begin
    NS = PS;
    case (PS)
        S0_FETCH:  NS = S1_DECODE;
        S1_DECODE: begin
            casex (instr_set)
                STOR:   NS = S3_STORE;
                LOAD:   NS = S4_LOAD;
                BRANCH: NS = S6_BRANCH;
                default: NS = S2_EXECUTE;
            endcase
        end
        S2_EXECUTE: NS = S0_FETCH;
        S3_STORE:   NS = S0_FETCH;
        S4_LOAD:    NS = S5_DOUT;
        S5_DOUT:    NS = S0_FETCH;
        S6_BRANCH:  NS = S0_FETCH;
        default:    NS = S0_FETCH;
    endcase
end

decoder u_decoder (
    .instr_set(instr_set),
    .Imm_in   (Imm_in),
    .opcode   (opcode),
    .Rdest    (Rdest_select),
    .Rsrc     (Rsrc_select)
);

always @(*) begin
    // defaults
    wEnable           = 16'b0;
    Imm_select        = 1'b0;
    pc_add_k          = 16'd0;
    pc_mux_selct      = 1'b0;
    pc_en             = 1'b0;
    we_a              = 1'b0;
    en_a              = 1'b0;
    en_b              = 1'b0;
    ram_wen           = 1'b0;
    lsc_mux_selct     = 1'b0;
    fsm_alu_mem_selct = 1'b0;
    decoder_en        = 1'b1;
    mmio_we           = 1'b0;  // MMIO default

    if ((opcode[7:4] != 4'h0) && (opcode != 8'h40) && (opcode != 8'h44))
        Imm_select = 1'b1;

    case (PS)
        S0_FETCH: begin
            en_a          = 1'b1;
            lsc_mux_selct = 1'b0;
        end

        S1_DECODE: begin
            // decoder runs continuously; no extra control needed
        end

        S2_EXECUTE: begin
            pc_en             = 1'b1;
            fsm_alu_mem_selct = 1'b0;
            if ((opcode == 8'h0B) || (opcode == 8'hB0) || (opcode == 8'h00))
                wEnable = 16'b0;
            else
                wEnable = (16'h0001 << Rdest_select);
        end

        S3_STORE: begin
            lsc_mux_selct = 1'b1;
            en_a          = 1'b1;
            we_a          = ~is_mmio;   // dont write to RAM when mmio value
            ram_wen       = ~is_mmio;
            mmio_we       = is_mmio;    // enable mmio write when mmio value
            pc_en         = 1'b1;
        end

        S4_LOAD: begin
            lsc_mux_selct     = 1'b1;
            en_a              = ~is_mmio;  // dont read from RAM when mmio value
            fsm_alu_mem_selct = 1'b1;
        end

        S5_DOUT: begin
            lsc_mux_selct     = 1'b1;
            fsm_alu_mem_selct = 1'b1;
            wEnable           = (16'h0001 << Rsrc_select);  
            pc_en             = 1'b1;
        end

        S6_BRANCH: begin
            pc_en    = 1'b1;
            pc_add_k = {{8{Imm_in[7]}}, Imm_in[7:0]};
            if (check_flags(Rdest_select, saved_flags))
                pc_mux_selct = 1'b1;
        end
    endcase
end

function integer check_flags;
    input [3:0] cond;
    input [4:0] flags;
    begin
        check_flags = 0;
        case (cond)
            EQ: check_flags = (flags[1] == 1'b1); // Z = 1
            NE: check_flags = (flags[1] == 1'b0); // Z = 0
            GE: check_flags = (flags[1] == 1'b1) || (flags[0] == 1'b1); // N = 0 or Z = 0
            CS: check_flags = (flags[3] == 1'b1); // C = 1
            CC: check_flags = (flags[3] == 1'b0); // C = 0
            HI: check_flags = (flags[4] == 1'b1); // L = 1
            LS: check_flags = (flags[4] == 1'b0); // L = 0
            LO: check_flags = (flags[4] == 1'b0) && (flags[1] == 1'b0); // L = 0 and Z = 0
            HS: check_flags = (flags[4] == 1'b1) || (flags[1] == 1'b1); // L = 1 or Z = 1
            GT: check_flags = (flags[0] == 1'b1); // N = 1
            LE: check_flags = (flags[0] == 1'b0); // N = 0
            FS: check_flags = (flags[2] == 1'b1); // F = 1
            FC: check_flags = (flags[2] == 1'b0); // F = 0
            LT: check_flags = (flags[0] == 1'b0) && (flags[1] == 1'b0); // N = 0 and Z = 0
            UC: check_flags = 1;    // always jump
            XX: check_flags = 0;    // never jump
            default: check_flags = 0; // don't jump
        endcase
    end
endfunction

endmodule
