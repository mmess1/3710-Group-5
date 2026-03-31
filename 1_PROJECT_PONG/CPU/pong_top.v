module pong_top (
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    output wire        VGA_CLK,
    output wire        VGA_HS,
    output wire        VGA_VS,
    output wire        VGA_BLANK_N,
    output wire [7:0]  VGA_R,
    output wire [7:0]  VGA_G,
    output wire [7:0]  VGA_B,
    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3
);

    wire reset_n = KEY[0];

    // ── CPU clock ─────────────────────────────────────────────────────────
    wire clk_cpu;
    clock_div #(.DIV(5)) u_cpu_clk (
        .clk_in (CLOCK_50),
        .reset  (~reset_n),
        .clk_out(clk_cpu)
    );

    // ── FSM <-> datapath wires ────────────────────────────────────────────
    wire [15:0] wEnable;
    wire [7:0]  opcode;
    wire [3:0]  Rdest_select, Rsrc_select;
    wire [15:0] Imm_in;
    wire        Imm_select;
    wire        we_a, en_a, en_b, ram_wen;
    wire        lsc_mux_select;
    wire [15:0] pc_add_k;
    wire        pc_mux_select, pc_en;
    wire        fsm_alu_mem_select;
    wire [15:0] ram_out;
    wire [4:0]  Flags_out;
    wire        decoder_en;  // unused, available for debug

    // ── MMIO wires ────────────────────────────────────────────────────────
    wire [15:0] mmio_addr; // address for mmio val     
    wire [15:0] mmio_wr_data; // data to write to mmio val
    wire [15:0] mmio_rd_data; // data to read mmio val
    wire        mmio_we; // enables write to mmio

    wire is_mmio = (mmio_addr >= 16'hFF00);

    // MMIO Registers
    reg [8:0]  reg_p1_y;    // 0xFF00  
    reg [8:0]  reg_p2_y;    // 0xFF01
	 //reg [15:0] reg_ball_x;  // 0xFF02
    //reg [15:0] reg_ball_y;  // 0xFF03

    always @(posedge clk_cpu or negedge reset_n) begin
        if (~reset_n) begin
            //reg_ball_x <= 16'd320;
            //reg_ball_y <= 16'd240;
            reg_p1_y   <= 9'd200;
            reg_p2_y   <= 9'd200;
        end else if (mmio_we) begin
            case (mmio_addr)
                16'hFF00: reg_p1_y   <= mmio_wr_data[8:0];
                16'hFF01: reg_p2_y   <= mmio_wr_data[8:0];
				//16'hFF02: reg_ball_x <= mmio_wr_data;
                //16'hFF03: reg_ball_y <= mmio_wr_data;
            endcase
        end
    end

    assign mmio_rd_data =
        (mmio_addr == 16'hFF00) ? {7'b0, reg_p1_y} :
        (mmio_addr == 16'hFF01) ? {7'b0, reg_p2_y} :
		//(mmio_addr == 16'hFF00) ? reg_ball_x        :
        //(mmio_addr == 16'hFF01) ? reg_ball_y        :
        16'h0000;

    // CPU
    pong_cpu_fsm fsm (
        .clk              (clk_cpu),
        .reset            (reset_n),
        .instr_set        (ram_out),
        .Flags_in         (Flags_out),
        .is_mmio          (is_mmio),
        .mmio_we          (mmio_we),
        .wEnable          (wEnable),
        .opcode           (opcode),
        .Rdest_select     (Rdest_select),
        .Rsrc_select      (Rsrc_select),
        .Imm_in           (Imm_in),
        .Imm_select       (Imm_select),
        .we_a             (we_a),
        .en_a             (en_a),
        .en_b             (en_b),
        .ram_wen          (ram_wen),
        .lsc_mux_selct    (lsc_mux_select),
        .pc_add_k         (pc_add_k),
        .pc_mux_selct     (pc_mux_select),
        .pc_en            (pc_en),
        .fsm_alu_mem_selct(fsm_alu_mem_select),
        .decoder_en       (decoder_en)
    );

    pong_dp #(.DATA_FILE("C:/Users/genet/altera_lite/quartus/ece3710/pong_test.hex")) dp (
        .clk              (clk_cpu),
        .reset            (reset_n),
        .ram_we           (ram_wen),
        .wEnable          (wEnable),
        .opcode           (opcode),
        .Flags_out        (Flags_out),
        .we_a             (we_a),
        .en_a             (en_a),
        .en_b             (en_b),
        .lsc_mux_select   (lsc_mux_select),
        .pc_add_k         (pc_add_k),
        .pc_mux_select    (pc_mux_select),
        .pc_en            (pc_en),
        .ram_out          (ram_out),
        .fsm_alu_mem_select(fsm_alu_mem_select),
        .Rdest_select     (Rdest_select),
        .Rsrc_select      (Rsrc_select),
        .Imm_in           (Imm_in),
        .Imm_select       (Imm_select),
        .ls_cntrl         (mmio_addr),
        .Rsrc_mux_out     (mmio_wr_data),
        .mmio_rd_data     (mmio_rd_data),
        .is_mmio          (is_mmio)
    );

    // VGA Display
    game_display gd (
        .CLOCK_50   (CLOCK_50),
        .KEY        (KEY),
        .p1_y       (reg_p1_y),
        .p2_y       (reg_p2_y),
        .VGA_CLK    (VGA_CLK),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_VS     (VGA_VS),
        .VGA_HS     (VGA_HS),
        .VGA_R      (VGA_R),
        .VGA_G      (VGA_G),
        .VGA_B      (VGA_B)
    );

    // displays changing y values for debugging
    hex7seg h0 (.hex(reg_p1_y[3:0]), .seg(HEX0));
    hex7seg h1 (.hex(reg_p1_y[7:4]), .seg(HEX1));
    hex7seg h2 (.hex(reg_p2_y[3:0]), .seg(HEX2));
    hex7seg h3 (.hex(reg_p2_y[7:4]), .seg(HEX3));

endmodule
