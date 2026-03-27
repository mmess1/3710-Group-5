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

    wire        sample_strobe;
    wire [8:0]  y_pos1;
    wire [8:0]  y_pos2;
    wire [9:0]  ball_x;
    wire [9:0]  ball_y;
    wire [3:0]  score1;
    wire [3:0]  score2;

    localparam [8:0] Y_MIN   = 9'd10;
    localparam [8:0] Y_MAX   = 9'd415;
    localparam [8:0] Y_RANGE = Y_MAX - Y_MIN;

    wire [2:0] p1_level;
    wire [2:0] p2_level;

    assign VGA_SYNC_N = 1'b0;
    assign LEDR       = 10'b0;

    assign p1_level = (y_pos1 <= Y_MIN) ? 3'd0 :
                      (y_pos1 >= Y_MAX) ? 3'd6 :
                      (((y_pos1 - Y_MIN) * 6) / Y_RANGE);

    assign p2_level = (y_pos2 <= Y_MIN) ? 3'd0 :
                      (y_pos2 >= Y_MAX) ? 3'd6 :
                      (((y_pos2 - Y_MIN) * 6) / Y_RANGE);

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

    function [6:0] hex_bar;
        input bottom_on;
        input top_on;
        begin
            hex_bar = 7'b1111111;
            if (top_on)
                hex_bar[0] = 1'b0;
            if (bottom_on)
                hex_bar[3] = 1'b0;
        end
    endfunction

    assign HEX0 = hex_bar((p1_level >= 3'd1), (p2_level >= 3'd1));
    assign HEX1 = hex_bar((p1_level >= 3'd2), (p2_level >= 3'd2));
    assign HEX2 = hex_bar((p1_level >= 3'd3), (p2_level >= 3'd3));
    assign HEX3 = hex_bar((p1_level >= 3'd4), (p2_level >= 3'd4));
    assign HEX4 = hex_bar((p1_level >= 3'd5), (p2_level >= 3'd5));
    assign HEX5 = hex_bar((p1_level >= 3'd6), (p2_level >= 3'd6));

endmodule