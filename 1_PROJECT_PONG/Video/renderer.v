module renderer(
    input  wire       CLOCK_50,
    input  wire [3:0] KEY,
    input  wire [8:0] y_pos1,
    input  wire [8:0] y_pos2,
    input  wire [9:0] ball_x,
    input  wire [9:0] ball_y,
    input  wire [3:0] score1,
    input  wire [3:0] score2,
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
    localparam PLAYER1_X     = 150;
    localparam PLAYER2_X     = 610;
    localparam BALL_SIZE     = 10;

    localparam SCORE_Y    = 40;
    localparam SCORE1_X   = 220;
    localparam SCORE2_X   = 380;
    localparam FONT_SCALE = 8;
    localparam DIGIT_W    = 5 * FONT_SCALE;
    localparam DIGIT_H    = 5 * FONT_SCALE;

    wire in_score1_box;
    wire in_score2_box;
    wire [2:0] score1_row;
    wire [2:0] score1_col;
    wire [2:0] score2_row;
    wire [2:0] score2_col;
    wire score1_on;
    wire score2_on;

    assign in_score1_box = (hcount >= SCORE1_X) && (hcount < SCORE1_X + DIGIT_W) &&
                           (vcount >= SCORE_Y)  && (vcount < SCORE_Y + DIGIT_H);

    assign in_score2_box = (hcount >= SCORE2_X) && (hcount < SCORE2_X + DIGIT_W) &&
                           (vcount >= SCORE_Y)  && (vcount < SCORE_Y + DIGIT_H);

    assign score1_row = (vcount - SCORE_Y) / FONT_SCALE;
    assign score1_col = (hcount - SCORE1_X) / FONT_SCALE;
    assign score2_row = (vcount - SCORE_Y) / FONT_SCALE;
    assign score2_col = (hcount - SCORE2_X) / FONT_SCALE;

    score_font left_digit (
        .digit(score1),
        .row(score1_row),
        .col(score1_col),
        .pixel_on(score1_on)
    );

    score_font right_digit (
        .digit(score2),
        .row(score2_row),
        .col(score2_col),
        .pixel_on(score2_on)
    );

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
                if (hcount < 10 || hcount >= 630 || vcount < 10 || vcount >= 470) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd0;
                end
                else if (hcount == 320 && (vcount % 20) < 10) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if ((in_score1_box && score1_on) || (in_score2_box && score2_on)) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if ((hcount >= PLAYER1_X) && (hcount < PLAYER1_X + PADDLE_WIDTH) &&
                         (vcount >= y_pos1)    && (vcount < y_pos1 + PADDLE_HEIGHT)) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if ((hcount >= PLAYER2_X) && (hcount < PLAYER2_X + PADDLE_WIDTH) &&
                         (vcount >= y_pos2)    && (vcount < y_pos2 + PADDLE_HEIGHT)) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if ((hcount >= ball_x) && (hcount < ball_x + BALL_SIZE) &&
                         (vcount >= ball_y) && (vcount < ball_y + BALL_SIZE)) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
            end
        end
    end

endmodule