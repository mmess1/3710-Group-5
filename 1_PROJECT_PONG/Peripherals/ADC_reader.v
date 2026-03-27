module PONG_TOP(
    input  wire       CLOCK_50,
    input  wire [3:0] KEY,

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

    wire [11:0] pot0_raw;
    wire [11:0] pot1_raw;
    wire        sample_strobe;

    wire [8:0] y_pos1;
    wire [8:0] y_pos2;
    wire [9:0] ball_x;
    wire [9:0] ball_y;
    wire [3:0] score1;
    wire [3:0] score2;

    wire [9:0] pot0_dec;
    wire [9:0] pot1_dec;

    wire [3:0] pot0_ones;
    wire [3:0] pot0_tens;
    wire [3:0] pot0_hundreds;

    wire [3:0] pot1_ones;
    wire [3:0] pot1_tens;
    wire [3:0] pot1_hundreds;

    assign VGA_SYNC_N = 1'b0;
    assign LEDR       = 10'b0;

    ADC_reader adc0 (
        .clk(CLOCK_50),
        .rst(KEY[0]),
        .ADC_DOUT(ADC_DOUT),
        .ADC_CS_N(ADC_CS_N),
        .ADC_DIN(ADC_DIN),
        .ADC_SCLK(ADC_SCLK),
        .pot0_raw(pot0_raw),
        .pot1_raw(pot1_raw),
        .sample_strobe(sample_strobe)
    );

    game_engine game0 (
        .clk(CLOCK_50),
        .rst(KEY[0]),
        .pot0_raw(pot0_raw),
        .pot1_raw(pot1_raw),
        .y_pos1(y_pos1),
        .y_pos2(y_pos2),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .score1(score1),
        .score2(score2)
    );

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

    // scale raw 0..4095 to decimal 0..999 for 3-digit display
    assign pot0_dec = (pot0_raw * 10'd999) / 12'd4095;
    assign pot1_dec = (pot1_raw * 10'd999) / 12'd4095;

    assign pot0_hundreds = pot0_dec / 10'd100;
    assign pot0_tens     = (pot0_dec % 10'd100) / 10'd10;
    assign pot0_ones     = pot0_dec % 10'd10;

    assign pot1_hundreds = pot1_dec / 10'd100;
    assign pot1_tens     = (pot1_dec % 10'd100) / 10'd10;
    assign pot1_ones     = pot1_dec % 10'd10;

    function [6:0] seg7_decimal;
        input [3:0] digit;
        begin
            case (digit)
                4'd0: seg7_decimal = 7'b1000000;
                4'd1: seg7_decimal = 7'b1111001;
                4'd2: seg7_decimal = 7'b0100100;
                4'd3: seg7_decimal = 7'b0110000;
                4'd4: seg7_decimal = 7'b0011001;
                4'd5: seg7_decimal = 7'b0010010;
                4'd6: seg7_decimal = 7'b0000010;
                4'd7: seg7_decimal = 7'b1111000;
                4'd8: seg7_decimal = 7'b0000000;
                4'd9: seg7_decimal = 7'b0010000;
                default: seg7_decimal = 7'b1111111;
            endcase
        end
    endfunction

    assign HEX0 = seg7_decimal(pot0_ones);
    assign HEX1 = seg7_decimal(pot0_tens);
    assign HEX2 = seg7_decimal(pot0_hundreds);

    assign HEX3 = seg7_decimal(pot1_ones);
    assign HEX4 = seg7_decimal(pot1_tens);
    assign HEX5 = seg7_decimal(pot1_hundreds);

endmodule