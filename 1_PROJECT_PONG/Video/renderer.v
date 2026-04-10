module renderer(
    input  wire       CLOCK_50,
    input  wire [3:0] KEY,
    input  wire [8:0] y_pos1,
    input  wire [8:0] y_pos2,
    input  wire [9:0] ball_x,
    input  wire [9:0] ball_y,
    input  wire [15:0] score1,
    input  wire [15:0] score2,
    output wire       VGA_CLK,
    output wire       VGA_BLANK_N,
    output wire       VGA_VS,
    output wire       VGA_HS,
    output reg  [7:0] VGA_R,
    output reg  [7:0] VGA_G,
    output reg  [7:0] VGA_B
);

    wire rst = KEY[0];
    wire [9:0] hcount;
    wire [9:0] vcount;

    localparam PADDLE_WIDTH  = 10;
    localparam PADDLE_HEIGHT = 45;
    localparam PLAYER1_X     = 30;
    localparam PLAYER2_X     = 610;
    localparam BALL_SIZE     = 10;

    localparam SCORE_Y          = 40;
    localparam SCORE1_X_ONES    = 220;
    localparam SCORE1_X_TENS    = SCORE1_X_ONES - 10 * 5;
    localparam SCORE2_X_TENS    = 380;
    localparam SCORE2_X_ONES    = (score2_tens < 0) ? (380 + 10 * 5) : 380;

    localparam FONT_SCALE = 8;
    localparam DIGIT_W    = 5 * FONT_SCALE;
    localparam DIGIT_H    = 5 * FONT_SCALE;

    wire [3:0] score1_tens;
    wire [3:0] score1_ones;
    wire [3:0] score2_tens;
    wire [3:0] score2_ones;

    wire [2:0] score1_row;
    wire [2:0] score1_col_ones;
    wire [2:0] score1_col_tens;
    wire [2:0] score2_row;
    wire [2:0] score2_col_ones;
    wire [2:0] score2_col_tens;

    wire in_score1_box_ones;
    wire in_score1_box_tens;
    wire in_score2_box_ones;
    wire in_score2_box_tens;

    wire score1_ones_pixel;
    wire score1_tens_pixel;
    wire score2_ones_pixel;
    wire score2_tens_pixel;

    wire score1_tens_visible = (score1 >= 16'd10);
    wire score2_tens_visible = (score2 >= 16'd10);

    assign score1_tens  = (score1 % 16'd100) / 16'd10;
    assign score1_ones  = score1 % 16'd10;
    assign score2_tens  = (score2 % 16'd100) / 16'd10;
    assign score2_ones  = score2 % 16'd10;

    assign in_score1_box_ones = (hcount >= SCORE1_X_ONES) && (hcount < SCORE1_X_ONES + DIGIT_W) &&
                                (vcount >= SCORE_Y) && (vcount < SCORE_Y + DIGIT_H);
    assign in_score1_box_tens = (hcount >= SCORE1_X_TENS) && (hcount < SCORE1_X_TENS + DIGIT_W) &&
                                (vcount >= SCORE_Y) && (vcount < SCORE_Y + DIGIT_H);
    assign in_score2_box_ones = (hcount >= SCORE2_X_ONES) && (hcount < SCORE2_X_ONES + DIGIT_W) &&
                                (vcount >= SCORE_Y) && (vcount < SCORE_Y + DIGIT_H);
    assign in_score2_box_tens = (hcount >= SCORE2_X_TENS) && (hcount < SCORE2_X_TENS + DIGIT_W) &&
                                (vcount >= SCORE_Y) && (vcount < SCORE_Y + DIGIT_H);

    assign score1_row       = (vcount - SCORE_Y) / FONT_SCALE;
    assign score1_col_ones  = (hcount >= SCORE1_X_ONES) ? (hcount - SCORE1_X_ONES) / FONT_SCALE : 3'd0;
    assign score1_col_tens  = (hcount >= SCORE1_X_TENS) ? (hcount - SCORE1_X_TENS) / FONT_SCALE : 3'd0;
    assign score2_row       = (vcount - SCORE_Y) / FONT_SCALE;
    assign score2_col_ones  = (hcount >= SCORE2_X_ONES) ? (hcount - SCORE2_X_ONES) / FONT_SCALE : 3'd0;
    assign score2_col_tens  = (hcount >= SCORE2_X_TENS) ? (hcount - SCORE2_X_TENS) / FONT_SCALE : 3'd0;

    score_font left_tens (
        .digit(score1_tens),
        .row(score1_row),
        .col(score1_col_tens),
        .pixel_on(score1_tens_pixel)
    );

    score_font left_ones (
        .digit(score1_ones),
        .row(score1_row),
        .col(score1_col_ones),
        .pixel_on(score1_ones_pixel)
    );

    score_font right_tens (
        .digit(score2_tens),
        .row(score2_row),
        .col(score2_col_tens),
        .pixel_on(score2_tens_pixel)
    );

    score_font right_ones (
        .digit(score2_ones),
        .row(score2_row),
        .col(score2_col_ones),
        .pixel_on(score2_ones_pixel)
    );

    wire score1_on = (in_score1_box_tens && score1_tens_visible && score1_tens_pixel) ||
                      (in_score1_box_ones && score1_ones_pixel);
    wire score2_on = (in_score2_box_tens && score2_tens_visible && score2_tens_pixel) ||
                      (in_score2_box_ones && score2_ones_pixel);

    clk_divider clk_div (
        .clk(CLOCK_50),
        .rst(rst),
        .div_clk(VGA_CLK)
    );

    vga_controller vga_ctrl (
        .vga_clk(VGA_CLK),
        .rst(rst),
        .vga_hs(VGA_HS),
        .vga_vs(VGA_VS),
        .vga_blank_n(VGA_BLANK_N),
        .hcount(hcount),
        .vcount(vcount)
    );

    always @(posedge VGA_CLK or negedge rst) begin
        if (~rst) begin
            VGA_R <= 8'd0;
            VGA_G <= 8'd0;
            VGA_B <= 8'd0;
        end else begin
            VGA_R <= 8'd0;
            VGA_G <= 8'd0;
            VGA_B <= 8'd0;

            if (VGA_BLANK_N) begin
                if (hcount < 5 || hcount >= 635 || vcount < 5 || vcount >= 475) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if (hcount == 320 && (vcount % 20) < 10) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if (score1_on || score2_on) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if ((hcount >= PLAYER1_X) && (hcount < PLAYER1_X + PADDLE_WIDTH) &&
                         (vcount >= y_pos1) && (vcount < y_pos1 + PADDLE_HEIGHT)) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if ((hcount >= PLAYER2_X) && (hcount < PLAYER2_X + PADDLE_WIDTH) &&
                         (vcount >= y_pos2) && (vcount < y_pos2 + PADDLE_HEIGHT)) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if ((hcount >= ball_x) && (hcount < ball_x + BALL_SIZE) &&
                         (vcount >= ball_y) && (vcount < ball_y + BALL_SIZE)) begin
                    VGA_R <= 8'd240;
                    VGA_G <= 8'd100;
                    VGA_B <= 8'd0;
                end
            end
        end
    end

endmodule
