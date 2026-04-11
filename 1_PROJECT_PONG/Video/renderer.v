module renderer(
    input  wire       CLOCK_50,
    input  wire [3:0] KEY,
    input  wire [8:0] y_pos1,
    input  wire [8:0] y_pos2,
    input  wire [9:0] ball_x,
    input  wire [9:0] ball_y,
    input  wire [15:0] score1,
    input  wire [15:0] score2,
    input  wire [1:0] screen_mode,
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

    localparam FONT_SCALE = 8;
    localparam DIGIT_W    = 5 * FONT_SCALE;
    localparam DIGIT_H    = 5 * FONT_SCALE;

    localparam MODE_START  = 2'd0;
    localparam MODE_PLAY   = 2'd1;
    localparam MODE_P1_WIN = 2'd2;
    localparam MODE_P2_WIN = 2'd3;

    localparam LOGO_W      = 24;
    localparam LOGO_H      = 5;
    localparam LOGO_SCALE  = 10;
    localparam LOGO_X      = (640 - LOGO_W * LOGO_SCALE) / 2;
    localparam LOGO_Y      = 120;

    localparam START_W     = 109;
    localparam START_H     = 8;
    localparam START_SCALE = 4;
    localparam START_X     = (640 - START_W * START_SCALE) / 2;
    localparam START_Y     = 300;
    localparam START_BASE  = START_W * START_H;

    localparam RESTART_W     = 124;
    localparam RESTART_H     = 8;
    localparam RESTART_SCALE = 3;
    localparam RESTART_X     = (640 - RESTART_W * RESTART_SCALE) / 2;
    localparam RESTART_Y     = 300;
    localparam RESTART_BASE  = RESTART_W * RESTART_H;

    localparam WIN_W      = 72;
    localparam WIN_H      = 6;
    localparam WIN_SCALE  = 6;
    localparam WIN_X      = (640 - WIN_W * WIN_SCALE) / 2;
    localparam WIN_Y      = 180;

    wire [3:0] score1_tens;
    wire [3:0] score1_ones;
    wire [3:0] score2_tens;
    wire [3:0] score2_ones;
    wire [9:0] score2_x_ones;

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

    wire border_on;
    wire center_on;

    wire in_logo_box;
    wire in_start_box;
    wire in_restart_box;
    wire in_win_box;

    wire [9:0] score1_row_full;
    wire [9:0] score1_col_ones_full;
    wire [9:0] score1_col_tens_full;
    wire [9:0] score2_row_full;
    wire [9:0] score2_col_ones_full;
    wire [9:0] score2_col_tens_full;

    wire [9:0] logo_lx_full;
    wire [9:0] logo_ly_full;
    wire [9:0] start_lx_full;
    wire [9:0] start_ly_full;
    wire [9:0] restart_lx_full;
    wire [9:0] restart_ly_full;
    wire [9:0] win_lx_full;
    wire [9:0] win_ly_full;

    wire [6:0]  logo_addr;
    wire [10:0] start_addr;
    wire [10:0] restart_addr;
    wire [8:0]  win_addr;

    wire [23:0] logo_rgb;
    wire [23:0] start_rgb;
    wire [23:0] restart_rgb;
    wire [23:0] p1_win_rgb;
    wire [23:0] p2_win_rgb;

    wire logo_on;
    wire start_on;
    wire restart_on;
    wire p1_win_on;
    wire p2_win_on;

    wire score1_on;
    wire score2_on;

    assign score1_tens   = (score1 % 16'd100) / 16'd10;
    assign score1_ones   = score1 % 16'd10;
    assign score2_tens   = (score2 % 16'd100) / 16'd10;
    assign score2_ones   = score2 % 16'd10;
    assign score2_x_ones = SCORE2_X_TENS + (score2_tens_visible ? DIGIT_W : 10'd0);

    assign in_score1_box_ones = (hcount >= SCORE1_X_ONES) && (hcount < SCORE1_X_ONES + DIGIT_W) &&
                                (vcount >= SCORE_Y) && (vcount < SCORE_Y + DIGIT_H);

    assign in_score1_box_tens = (hcount >= SCORE1_X_TENS) && (hcount < SCORE1_X_TENS + DIGIT_W) &&
                                (vcount >= SCORE_Y) && (vcount < SCORE_Y + DIGIT_H);

    assign in_score2_box_ones = (hcount >= score2_x_ones) && (hcount < score2_x_ones + DIGIT_W) &&
                                (vcount >= SCORE_Y) && (vcount < SCORE_Y + DIGIT_H);

    assign in_score2_box_tens = (hcount >= SCORE2_X_TENS) && (hcount < SCORE2_X_TENS + DIGIT_W) &&
                                (vcount >= SCORE_Y) && (vcount < SCORE_Y + DIGIT_H);

    assign score1_row_full      = (vcount >= SCORE_Y) ? (vcount - SCORE_Y) / FONT_SCALE : 10'd0;
    assign score1_col_ones_full = (hcount >= SCORE1_X_ONES) ? (hcount - SCORE1_X_ONES) / FONT_SCALE : 10'd0;
    assign score1_col_tens_full = (hcount >= SCORE1_X_TENS) ? (hcount - SCORE1_X_TENS) / FONT_SCALE : 10'd0;
    assign score2_row_full      = (vcount >= SCORE_Y) ? (vcount - SCORE_Y) / FONT_SCALE : 10'd0;
    assign score2_col_ones_full = (hcount >= score2_x_ones) ? (hcount - score2_x_ones) / FONT_SCALE : 10'd0;
    assign score2_col_tens_full = (hcount >= SCORE2_X_TENS) ? (hcount - SCORE2_X_TENS) / FONT_SCALE : 10'd0;

    assign score1_row      = score1_row_full[2:0];
    assign score1_col_ones = score1_col_ones_full[2:0];
    assign score1_col_tens = score1_col_tens_full[2:0];
    assign score2_row      = score2_row_full[2:0];
    assign score2_col_ones = score2_col_ones_full[2:0];
    assign score2_col_tens = score2_col_tens_full[2:0];

    assign border_on = (hcount < 5) || (hcount >= 635) || (vcount < 5) || (vcount >= 475);
    assign center_on = (hcount == 320) && ((vcount % 20) < 10);

    assign in_logo_box = (hcount >= LOGO_X) && (hcount < LOGO_X + LOGO_W * LOGO_SCALE) &&
                         (vcount >= LOGO_Y) && (vcount < LOGO_Y + LOGO_H * LOGO_SCALE);

    assign in_start_box = (hcount >= START_X) && (hcount < START_X + START_W * START_SCALE) &&
                          (vcount >= START_Y) && (vcount < START_Y + START_H * START_SCALE);

    assign in_restart_box = (hcount >= RESTART_X) && (hcount < RESTART_X + RESTART_W * RESTART_SCALE) &&
                            (vcount >= RESTART_Y) && (vcount < RESTART_Y + RESTART_H * RESTART_SCALE);

    assign in_win_box = (hcount >= WIN_X) && (hcount < WIN_X + WIN_W * WIN_SCALE) &&
                        (vcount >= WIN_Y) && (vcount < WIN_Y + WIN_H * WIN_SCALE);

    assign logo_lx_full = in_logo_box ? (hcount - LOGO_X) / LOGO_SCALE : 10'd0;
    assign logo_ly_full = in_logo_box ? (vcount - LOGO_Y) / LOGO_SCALE : 10'd0;

    assign start_lx_full = in_start_box ? (hcount - START_X) / START_SCALE : 10'd0;
    assign start_ly_full = in_start_box ? (vcount - START_Y) / START_SCALE : 10'd0;

    assign restart_lx_full = in_restart_box ? (hcount - RESTART_X) / RESTART_SCALE : 10'd0;
    assign restart_ly_full = in_restart_box ? (vcount - RESTART_Y) / RESTART_SCALE : 10'd0;

    assign win_lx_full = in_win_box ? (hcount - WIN_X) / WIN_SCALE : 10'd0;
    assign win_ly_full = in_win_box ? (vcount - WIN_Y) / WIN_SCALE : 10'd0;

    assign logo_addr    = logo_ly_full * LOGO_W + logo_lx_full;
    assign start_addr   = START_BASE + start_ly_full * START_W + start_lx_full;
    assign restart_addr = RESTART_BASE + restart_ly_full * RESTART_W + restart_lx_full;
    assign win_addr     = win_ly_full * WIN_W + win_lx_full;

    assign logo_on    = in_logo_box && (logo_rgb != 24'h000000);
    assign start_on   = in_start_box && (start_rgb != 24'h000000);
    assign restart_on = in_restart_box && (restart_rgb != 24'h000000);
    assign p1_win_on  = in_win_box && (p1_win_rgb != 24'h000000);
    assign p2_win_on  = in_win_box && (p2_win_rgb != 24'h000000);

    assign score1_on = (in_score1_box_tens && score1_tens_visible && score1_tens_pixel) ||
                       (in_score1_box_ones && score1_ones_pixel);

    assign score2_on = (in_score2_box_tens && score2_tens_visible && score2_tens_pixel) ||
                       (in_score2_box_ones && score2_ones_pixel);

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

    glyph_rom #(
        .DATA_FILE("Glyphs/Pong_logo_new.hex"),
        .ADDR_WIDTH(7),
        .DEPTH(120)
    ) logo_rom (
        .addr(logo_addr),
        .pixel(logo_rgb)
    );

    glyph_rom #(
        .DATA_FILE("Glyphs/Press_to_start.hex"),
        .ADDR_WIDTH(11),
        .DEPTH(1744)
    ) start_rom (
        .addr(start_addr),
        .pixel(start_rgb)
    );

    glyph_rom #(
        .DATA_FILE("Glyphs/Press_to_restart.hex"),
        .ADDR_WIDTH(11),
        .DEPTH(1984)
    ) restart_rom (
        .addr(restart_addr),
        .pixel(restart_rgb)
    );

    glyph_rom #(
        .DATA_FILE("Glyphs/PLAYER_1_WINS.hex"),
        .ADDR_WIDTH(9),
        .DEPTH(432)
    ) p1_win_rom (
        .addr(win_addr),
        .pixel(p1_win_rgb)
    );

    glyph_rom #(
        .DATA_FILE("Glyphs/PLAYER_2_WINS.hex"),
        .ADDR_WIDTH(9),
        .DEPTH(432)
    ) p2_win_rom (
        .addr(win_addr),
        .pixel(p2_win_rgb)
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
                if (border_on) begin
                    VGA_R <= 8'd255;
                    VGA_G <= 8'd255;
                    VGA_B <= 8'd255;
                end
                else if (screen_mode == MODE_START) begin
                    if (logo_on) begin
                        VGA_R <= logo_rgb[23:16];
                        VGA_G <= logo_rgb[15:8];
                        VGA_B <= logo_rgb[7:0];
                    end
                    else if (start_on) begin
                        VGA_R <= start_rgb[23:16];
                        VGA_G <= start_rgb[15:8];
                        VGA_B <= start_rgb[7:0];
                    end
                end
                else if (screen_mode == MODE_P1_WIN) begin
                    if (p1_win_on) begin
                        VGA_R <= p1_win_rgb[23:16];
                        VGA_G <= p1_win_rgb[15:8];
                        VGA_B <= p1_win_rgb[7:0];
                    end
                    else if (restart_on) begin
                        VGA_R <= restart_rgb[23:16];
                        VGA_G <= restart_rgb[15:8];
                        VGA_B <= restart_rgb[7:0];
                    end
                end
                else if (screen_mode == MODE_P2_WIN) begin
                    if (p2_win_on) begin
                        VGA_R <= p2_win_rgb[23:16];
                        VGA_G <= p2_win_rgb[15:8];
                        VGA_B <= p2_win_rgb[7:0];
                    end
                    else if (restart_on) begin
                        VGA_R <= restart_rgb[23:16];
                        VGA_G <= restart_rgb[15:8];
                        VGA_B <= restart_rgb[7:0];
                    end
                end
                else begin
                    if (center_on) begin
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
    end

endmodule

module glyph_rom
#(
    parameter DATA_FILE = "",
    parameter ADDR_WIDTH = 10,
    parameter DEPTH = 1024
)
(
    input  wire [ADDR_WIDTH-1:0] addr,
    output wire [23:0] pixel
);

    reg [23:0] rom [0:DEPTH-1];
    integer i;

    initial begin
        for (i = 0; i < DEPTH; i = i + 1)
            rom[i] = 24'h000000;

        $readmemh(DATA_FILE, rom);
    end

    assign pixel = rom[addr];

endmodule