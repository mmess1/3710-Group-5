module PONG_TOP(
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [35:0] GPIO_1,

    output wire [9:0] LEDR,

    output wire       ADC_CS_N,
    output wire       ADC_DIN,
    input  wire       ADC_DOUT,
    output wire       ADC_SCLK,

    output wire [6:0] HEX0,
    output wire [6:0] HEX1,
    output wire [6:0] HEX2,
    output wire [6:0] HEX3,
    output wire [6:0] HEX4,
    output wire [6:0] HEX5,

    output wire       VGA_CLK,
    output wire       VGA_BLANK_N,
    output wire       VGA_SYNC_N,
    output wire       VGA_VS,
    output wire       VGA_HS,
    output wire [7:0] VGA_R,
    output wire [7:0] VGA_G,
    output wire [7:0] VGA_B
);

    wire reset_n;
    assign reset_n = KEY[0];

    reg  [4:0] cpu_div;
    wire       clk_cpu;
    wire       cpu_reset_n;

    reg        key1_d;
    reg        game_started;
    reg  [1:0] winner_mode;
    wire       start_pressed;
    wire [1:0] screen_mode;

    wire [8:0] mcu_pot0;
    wire [8:0] mcu_pot1;
    wire [8:0] adc_p1_y;
    wire [8:0] adc_p2_y;

    wire [15:0] wEnable;
    wire [7:0]  opcode;
    wire [3:0]  Rdest_select;
    wire [3:0]  Rsrc_select;
    wire [15:0] Imm_in;
    wire        Imm_select;
    wire        we_a;
    wire        en_a;
    wire        en_b;
    wire        ram_wen;
    wire        lsc_mux_select;
    wire [15:0] pc_add_k;
    wire        pc_mux_select;
    wire        pc_en;
    wire        fsm_alu_mem_select;
    wire [15:0] ram_out;
    wire [4:0]  Flags_out;
    wire        decoder_en;

    wire [15:0] mmio_addr;
    wire [15:0] mmio_wr_data;
    wire [15:0] mmio_rd_data;
    wire        mmio_we;
    wire        is_mmio;

    reg  [8:0] reg_p1_y;
    reg  [8:0] reg_p2_y;

    wire [8:0] y_pos1;
    wire [8:0] y_pos2;
    wire [9:0] ball_x;
    wire [9:0] ball_y;
    wire [3:0] score1;
    wire [3:0] score2;

    wire [3:0] p1_hundreds;
    wire [3:0] p1_tens;
    wire [3:0] p1_ones;
    wire [3:0] p2_hundreds;
    wire [3:0] p2_tens;
    wire [3:0] p2_ones;
	 
	 wire [15:0] r0,  r1,  r2,  r3,  r4,  r5;
	wire [15:0] r6,  r7,  r8,  r9,  r10;
	wire [15:0] r11, r12, r13, r14, r15;

    assign clk_cpu      = cpu_div[4];
    assign start_pressed = key1_d && ~KEY[1];
    assign cpu_reset_n  = reset_n && game_started && (winner_mode == 2'd0);
    assign screen_mode  = !game_started ? 2'd0 :
                          (winner_mode != 2'd0) ? winner_mode : 2'd1;

    assign is_mmio    = (mmio_addr >= 16'hFF00);
    assign VGA_SYNC_N = 1'b0;
    assign LEDR       = {1'b0, adc_p1_y};

    // keep old adc pins present for board pin compatibility
    // this top still uses the gpio mcu adc path through ADC_reader
    assign ADC_CS_N = 1'b1;
    assign ADC_DIN  = 1'b0;
    assign ADC_SCLK = 1'b0;

    // jp2 gpio_1 mapping
    assign mcu_pot0 = {GPIO_1[34], GPIO_1[32], GPIO_1[30], GPIO_1[28], GPIO_1[26],
                       GPIO_1[27], GPIO_1[29], GPIO_1[31], GPIO_1[33]};

    assign mcu_pot1 = {GPIO_1[24], GPIO_1[22], GPIO_1[20], GPIO_1[18], GPIO_1[16],
                       GPIO_1[14], GPIO_1[12], GPIO_1[10], GPIO_1[11]};

    always @(posedge CLOCK_50 or negedge reset_n) begin
        if (!reset_n) begin
            cpu_div <= 5'd0;
            key1_d <= 1'b1;
            game_started <= 1'b0;
            winner_mode <= 2'd0;
        end else begin
            cpu_div <= cpu_div + 5'd1;
            key1_d <= KEY[1];

            if (!game_started) begin
                winner_mode <= 2'd0;

                if (start_pressed)
                    game_started <= 1'b1;
            end
            else if (winner_mode == 2'd0) begin
                if (r4 >= 16'd15)
                    winner_mode <= 2'd2;
                else if (r5 >= 16'd15)
                    winner_mode <= 2'd3;
            end
        end
    end

    ADC_reader adc0 (
        .clk    (CLOCK_50),
        .rst    (reset_n),
        .mcu_pot0(mcu_pot0),
        .mcu_pot1(mcu_pot1),
        .y_pos1 (adc_p1_y),
        .y_pos2 (adc_p2_y)
    );

    always @(posedge clk_cpu or negedge reset_n) begin
        if (!reset_n) begin
            reg_p1_y <= 9'd200;
            reg_p2_y <= 9'd200;
        end else if (mmio_we) begin
            case (mmio_addr)
                16'hFF00: reg_p1_y <= mmio_wr_data[8:0];
                16'hFF01: reg_p2_y <= mmio_wr_data[8:0];
            endcase
        end
    end

    assign mmio_rd_data =
        (mmio_addr == 16'hFF00) ? {7'b0, reg_p1_y} :
        (mmio_addr == 16'hFF01) ? {7'b0, reg_p2_y} :
        (mmio_addr == 16'hFF10) ? {7'b0, adc_p1_y} :
        (mmio_addr == 16'hFF11) ? {7'b0, adc_p2_y} :
        16'h0000;

    pong_cpu_fsm fsm (
        .clk               (clk_cpu),
        .reset             (cpu_reset_n),
        .instr_set         (ram_out),
        .Flags_in          (Flags_out),
        .wEnable           (wEnable),
        .opcode            (opcode),
        .Rdest_select      (Rdest_select),
        .Rsrc_select       (Rsrc_select),
        .Imm_in            (Imm_in),
        .Imm_select        (Imm_select),
        .we_a              (we_a),
        .en_a              (en_a),
        .en_b              (en_b),
        .ram_wen           (ram_wen),
        .lsc_mux_selct     (lsc_mux_select),
        .pc_add_k          (pc_add_k),
        .pc_mux_selct      (pc_mux_select),
        .pc_en             (pc_en),
        .fsm_alu_mem_selct (fsm_alu_mem_select),
        .decoder_en        (decoder_en),
        .is_mmio           (is_mmio),
        .mmio_we           (mmio_we)
    );

    pong_dp #(.DATA_FILE("PONG.bin")) dp (
        .clk               (clk_cpu),
        .reset             (cpu_reset_n),
        .ram_we            (ram_wen),
        .wEnable           (wEnable),
        .opcode            (opcode),
        .Flags_out         (Flags_out),
        .we_a              (we_a),
        .en_a              (en_a),
        .en_b              (en_b),
        .lsc_mux_select    (lsc_mux_select),
        .pc_add_k          (pc_add_k),
        .pc_mux_select     (pc_mux_select),
        .pc_en             (pc_en),
        .ram_out           (ram_out),
        .fsm_alu_mem_select(fsm_alu_mem_select),
        .Rdest_select      (Rdest_select),
        .Rsrc_select       (Rsrc_select),
        .Imm_in            (Imm_in),
        .Imm_select        (Imm_select),
        .ls_cntrl          (mmio_addr),
        .Rsrc_mux_out      (mmio_wr_data),
        .mmio_rd_data      (mmio_rd_data),
        .is_mmio           (is_mmio),
		  .player1_y(adc_p1_y),
		  .player2_y(adc_p2_y),
		  .r0 (r0),  .r1 (r1),  .r2 (r2),  .r3 (r3),
		  .r4 (r4),  .r5 (r5),  .r6 (r6),  .r7 (r7),
		  .r8 (r8),  .r9 (r9),  .r10(r10), .r11(r11),
		  .r12(r12), .r13(r13), .r14(r14), .r15(r15)
    );

    renderer video0 (
        .CLOCK_50    (CLOCK_50),
        .KEY         (KEY),
        .y_pos1      (r1),
        .y_pos2      (r3),
        .ball_x      (r6),
        .ball_y      (r7),
        .score1      (r4),
        .score2      (r5),
        .screen_mode (screen_mode),
        .VGA_CLK     (VGA_CLK),
        .VGA_BLANK_N (VGA_BLANK_N),
        .VGA_VS      (VGA_VS),
        .VGA_HS      (VGA_HS),
        .VGA_R       (VGA_R),
        .VGA_G       (VGA_G),
        .VGA_B       (VGA_B)
    );

    function [6:0] seg7_hex;
        input [3:0] digit;
        begin
            case (digit)
                4'h0: seg7_hex = 7'b1000000;
                4'h1: seg7_hex = 7'b1111001;
                4'h2: seg7_hex = 7'b0100100;
                4'h3: seg7_hex = 7'b0110000;
                4'h4: seg7_hex = 7'b0011001;
                4'h5: seg7_hex = 7'b0010010;
                4'h6: seg7_hex = 7'b0000010;
                4'h7: seg7_hex = 7'b1111000;
                4'h8: seg7_hex = 7'b0000000;
                4'h9: seg7_hex = 7'b0010000;
                4'hA: seg7_hex = 7'b0001000;
                4'hB: seg7_hex = 7'b0000011;
                4'hC: seg7_hex = 7'b1000110;
                4'hD: seg7_hex = 7'b0100001;
                4'hE: seg7_hex = 7'b0000110;
                4'hF: seg7_hex = 7'b0001110;
                default: seg7_hex = 7'b1111111;
            endcase
        end
    endfunction

    assign p1_hundreds = reg_p1_y / 9'd100;
    assign p1_tens     = (reg_p1_y % 9'd100) / 9'd10;
    assign p1_ones     = reg_p1_y % 9'd10;

    assign p2_hundreds = reg_p2_y / 9'd100;
    assign p2_tens     = (reg_p2_y % 9'd100) / 9'd10;
    assign p2_ones     = reg_p2_y % 9'd10;

    assign HEX0 = seg7_hex(p1_ones);
    assign HEX1 = seg7_hex(p1_tens);
    assign HEX2 = seg7_hex(p1_hundreds);
    assign HEX3 = seg7_hex(p2_ones);
    assign HEX4 = seg7_hex(p2_tens);
    assign HEX5 = seg7_hex(p2_hundreds);

endmodule