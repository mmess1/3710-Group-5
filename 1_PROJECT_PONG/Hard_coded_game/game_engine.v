module game_engine(
    input  wire       clk,
    input  wire       rst,          // active low
    input  wire [11:0] adc0_raw,
    input  wire [11:0] adc1_raw,
    output reg  [8:0] y_pos1,
    output reg  [8:0] y_pos2,
    output reg [9:0]  ball_x,
    output reg [9:0]  ball_y,
    output reg [3:0]  score1,
    output reg [3:0]  score2
);

    localparam integer COUNT = 1_250_000;

    localparam [8:0] Y_TOP          = 9'd10;
    localparam [8:0] PADDLE_HEIGHT  = 9'd45;
    localparam [8:0] Y_BOTTOM       = 9'd470 - PADDLE_HEIGHT - 9'd10;
    localparam [8:0] Y_RANGE        = Y_BOTTOM - Y_TOP;

    // use your observed real max so full pot travel maps cleanly
    localparam [11:0] ADC_MAX_REAL  = 12'd2500;

    reg [20:0] counter;
    reg        tick;
    reg        direction;

    function [8:0] map_adc_to_y;
        input [11:0] raw;
        reg   [11:0] clipped;
        reg   [20:0] scaled_num;
        reg   [8:0]  scaled_y;
        begin
            clipped    = (raw > ADC_MAX_REAL) ? ADC_MAX_REAL : raw;
            scaled_num = clipped * Y_RANGE;
            scaled_y   = scaled_num / ADC_MAX_REAL;

            // lowest raw = bottom of screen
            // highest raw = top of screen
            map_adc_to_y = Y_BOTTOM - scaled_y;
        end
    endfunction

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            counter <= 21'd0;
            tick    <= 1'b0;
        end else if (counter == COUNT - 1) begin
            counter <= 21'd0;
            tick    <= 1'b1;
        end else begin
            counter <= counter + 21'd1;
            tick    <= 1'b0;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            y_pos1    <= 9'd150;
            y_pos2    <= 9'd150;
            ball_x    <= 10'd315;
            ball_y    <= 10'd235;
            score1    <= 4'd0;
            score2    <= 4'd0;
            direction <= 1'b0;
        end else begin
            y_pos1 <= map_adc_to_y(adc0_raw);
            y_pos2 <= map_adc_to_y(adc1_raw);

            if (tick) begin
                if (!direction) begin
                    if (ball_x >= 10'd620) begin
                        ball_x    <= 10'd315;
                        ball_y    <= 10'd235;
                        direction <= 1'b1;
                        score1    <= (score1 == 4'd9) ? 4'd0 : (score1 + 4'd1);
                    end else begin
                        ball_x <= ball_x + 10'd1;
                    end
                end else begin
                    if (ball_x <= 10'd10) begin
                        ball_x    <= 10'd315;
                        ball_y    <= 10'd235;
                        direction <= 1'b0;
                        score2    <= (score2 == 4'd9) ? 4'd0 : (score2 + 4'd1);
                    end else begin
                        ball_x <= ball_x - 10'd1;
                    end
                end
            end
        end
    end

endmodule