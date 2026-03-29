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

    // Internal wires for MCU inputs game state and display digits.
    wire [8:0] mcu_pot0;
    wire [8:0] mcu_pot1;

    wire [8:0] pot0_raw;
    wire [8:0] pot1_raw;
    wire [8:0] pot0_y;
    wire [8:0] pot1_y;
    wire [8:0] y_pos1;
    wire [8:0] y_pos2;
    wire [9:0] ball_x;
    wire [9:0] ball_y;
    wire [3:0] score1;
    wire [3:0] score2;

    wire [3:0] pot0_hundreds;
    wire [3:0] pot0_tens;
    wire [3:0] pot0_ones;
    wire [3:0] pot1_hundreds;
    wire [3:0] pot1_tens;
    wire [3:0] pot1_ones;

    // Fixed top-level output ties.
    assign VGA_SYNC_N = 1'b0;
    assign LEDR       = 10'b0;

    // Old LTC2308 path is disabled. Keep ports tied off so existing pin assignments still compile cleanly.
    assign ADC_CS_N = 1'b1;
    assign ADC_DIN  = 1'b0;
    assign ADC_SCLK = 1'b0;

    // JP2 / GPIO_1 physical pin mapping requested by wiring order:
    assign mcu_pot0 = {GPIO_1[34], GPIO_1[32], GPIO_1[30], GPIO_1[28], GPIO_1[26],
                       GPIO_1[27], GPIO_1[29], GPIO_1[31], GPIO_1[33]};

    assign mcu_pot1 = {GPIO_1[24], GPIO_1[22], GPIO_1[20], GPIO_1[18], GPIO_1[16],
                       GPIO_1[14], GPIO_1[12], GPIO_1[10], GPIO_1[11]};

    // ADC input remap and paddle position generation.
    ADC_reader adc0 (
        .clk(CLOCK_50),
        .rst(KEY[0]),
        .mcu_pot0(mcu_pot0),
        .mcu_pot1(mcu_pot1),
        .pot0_raw(pot0_raw),
        .pot1_raw(pot1_raw),
        .y_pos1(pot0_y),
        .y_pos2(pot1_y)
    );

    // Main game state update logic.
    game_engine game0 (
        .clk(CLOCK_50),
        .rst(KEY[0]),
        .y_pos1_in(pot0_y),
        .y_pos2_in(pot1_y),
        .y_pos1(y_pos1),
        .y_pos2(y_pos2),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .score1(score1),
        .score2(score2)
    );

    // VGA renderer for paddles ball and score.
    renderer video0 (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .y_pos1(y_pos1),
        .y_pos2(y_pos2),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .score1(score1),
        .score2(score2),
        .VGA_CLK(VGA_CLK),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_VS(VGA_VS),
        .VGA_HS(VGA_HS),
        .VGA_R(VGA_R),
        .VGA_G(VGA_G),
        .VGA_B(VGA_B)
    );

    // Seven-segment hex decoder function.
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

    // Split pot0 value into decimal digits.
    assign pot0_hundreds = pot0_raw / 9'd100;
    assign pot0_tens     = (pot0_raw % 9'd100) / 9'd10;
    assign pot0_ones     = pot0_raw % 9'd10;

    // Split pot1 value into decimal digits.
    assign pot1_hundreds = pot1_raw / 9'd100;
    assign pot1_tens     = (pot1_raw % 9'd100) / 9'd10;
    assign pot1_ones     = pot1_raw % 9'd10;

    // Drive HEX displays with converted pot values.
    assign HEX0 = seg7_hex(pot0_ones);
    assign HEX1 = seg7_hex(pot0_tens);
    assign HEX2 = seg7_hex(pot0_hundreds);

    assign HEX3 = seg7_hex(pot1_ones);
    assign HEX4 = seg7_hex(pot1_tens);
    assign HEX5 = seg7_hex(pot1_hundreds);

endmodule
