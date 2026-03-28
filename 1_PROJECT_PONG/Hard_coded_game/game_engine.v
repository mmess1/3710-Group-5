module game_engine(
    input  wire        clk,
    input  wire        rst,          // active low
    input  wire [11:0] adc0_raw,
    input  wire [11:0] adc1_raw,
    output reg  [8:0]  y_pos1,
    output reg  [8:0]  y_pos2,
    output reg  [9:0]  ball_x,
    output reg  [9:0]  ball_y,
    output reg  [3:0]  score1,
    output reg  [3:0]  score2
);

    localparam integer COUNT = 1_250_000;

    localparam [8:0] Y_TOP         = 9'd10;
    localparam [8:0] PADDLE_HEIGHT = 9'd45;
    localparam [8:0] Y_BOTTOM      = 9'd470 - PADDLE_HEIGHT - 9'd10;
    localparam [8:0] Y_RANGE       = Y_BOTTOM - Y_TOP;

    reg [20:0] counter;
    reg        tick;
    reg        direction;

    reg [11:0] adc0_min;
    reg [11:0] adc0_max;
    reg [11:0] adc1_min;
    reg [11:0] adc1_max;

    function [8:0] map_adc_to_y;
        input [11:0] raw;
        input [11:0] min_val;
        input [11:0] max_val;
        reg   [11:0] clipped;
        reg   [12:0] span;
        reg   [20:0] scaled_num;
        reg   [8:0]  scaled_y;
        reg   [8:0]  mapped_y;
        begin
            if (max_val <= min_val + 12'd4) begin
                map_adc_to_y = Y_BOTTOM;
            end else begin
                if (raw <= min_val)
                    clipped = min_val;
                else if (raw >= max_val)
                    clipped = max_val;
                else
                    clipped = raw;

                span       = max_val - min_val;
                scaled_num = (clipped - min_val) * Y_RANGE;
                scaled_y   = scaled_num / span;
                mapped_y   = Y_BOTTOM - scaled_y;

                if (mapped_y < Y_TOP)
                    map_adc_to_y = Y_TOP;
                else if (mapped_y > Y_BOTTOM)
                    map_adc_to_y = Y_BOTTOM;
                else
                    map_adc_to_y = mapped_y;
            end
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
            adc0_min   <= 12'd4095;
            adc0_max   <= 12'd0;
            adc1_min   <= 12'd4095;
            adc1_max   <= 12'd0;

            y_pos1     <= Y_BOTTOM;
            y_pos2     <= Y_BOTTOM;
            ball_x     <= 10'd315;
            ball_y     <= 10'd235;
            score1     <= 4'd0;
            score2     <= 4'd0;
            direction  <= 1'b0;
        end else begin
            if (adc0_raw < adc0_min)
                adc0_min <= adc0_raw;
            if (adc0_raw > adc0_max)
                adc0_max <= adc0_raw;

            if (adc1_raw < adc1_min)
                adc1_min <= adc1_raw;
            if (adc1_raw > adc1_max)
                adc1_max <= adc1_raw;

            y_pos1 <= map_adc_to_y(adc0_raw, adc0_min, adc0_max);
            y_pos2 <= map_adc_to_y(adc1_raw, adc1_min, adc1_max);

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