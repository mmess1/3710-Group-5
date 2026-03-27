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

    wire       sample_strobe;

    wire [8:0] y_pos1;
    wire [8:0] y_pos2;
    wire [9:0] ball_x;
    wire [9:0] ball_y;
    wire [3:0] score1;
    wire [3:0] score2;

    wire [9:0] p1_dec;
    wire [9:0] p2_dec;

    wire [3:0] p1_ones;
    wire [3:0] p1_tens;
    wire [3:0] p1_hundreds;

    wire [3:0] p2_ones;
    wire [3:0] p2_tens;
    wire [3:0] p2_hundreds;

    assign VGA_SYNC_N = 1'b0;
    assign LEDR       = 10'b0;

    ADC_reader adc0 (
        .clk(CLOCK_50),
        .rst(KEY[0]),
        .ADC_DOUT(ADC_DOUT),
        .ADC_CS_N(ADC_CS_N),
        .ADC_DIN(ADC_DIN),
        .ADC_SCLK(ADC_SCLK),
        .y_pos1(y_pos1),
        .y_pos2(y_pos2),
        .sample_strobe(sample_strobe)
    );

    game_engine game0 (
        .clk(CLOCK_50),
        .rst(KEY[0]),
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

    assign p1_dec = y_pos1;
    assign p2_dec = y_pos2;

    assign p1_hundreds = p1_dec / 10'd100;
    assign p1_tens     = (p1_dec % 10'd100) / 10'd10;
    assign p1_ones     = p1_dec % 10'd10;

    assign p2_hundreds = p2_dec / 10'd100;
    assign p2_tens     = (p2_dec % 10'd100) / 10'd10;
    assign p2_ones     = p2_dec % 10'd10;

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

    assign HEX0 = seg7_decimal(p1_ones);
    assign HEX1 = seg7_decimal(p1_tens);
    assign HEX2 = seg7_decimal(p1_hundreds);

    assign HEX3 = seg7_decimal(p2_ones);
    assign HEX4 = seg7_decimal(p2_tens);
    assign HEX5 = seg7_decimal(p2_hundreds);

endmodule