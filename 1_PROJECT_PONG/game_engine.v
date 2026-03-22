module game_engine(
    input  wire       clk,
    input  wire       rst,
    output reg  [8:0] y_pos1,
    output reg  [8:0] y_pos2,
    output reg  [9:0] ball_x,
    output reg  [9:0] ball_y,
    output reg  [3:0] score1,
    output reg  [3:0] score2
);

    localparam COUNT = 1250000;

    reg [20:0] counter;
    reg tick;

    reg up;
    reg down;
    reg direction;

    // slow tick generator
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            counter <= 21'd0;
            tick    <= 1'b0;
        end else if (counter == COUNT) begin
            counter <= 21'd0;
            tick    <= 1'b1;
        end else begin
            counter <= counter + 21'd1;
            tick    <= 1'b0;
        end
    end

    // simple game engine
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            y_pos1    <= 9'd150;
            y_pos2    <= 9'd150;
            ball_x    <= 10'd315;
            ball_y    <= 10'd235;
            score1    <= 4'd0;
            score2    <= 4'd0;
            down      <= 1'b1;
            up        <= 1'b0;
            direction <= 1'b0;
        end else if (tick) begin
            // paddle float motion
            if (down) begin
                if (y_pos1 >= 9'd350) begin
                    down   <= 1'b0;
                    up     <= 1'b1;
                    y_pos1 <= y_pos1 - 9'd1;
                    y_pos2 <= y_pos2 - 9'd1;
                end else begin
                    y_pos1 <= y_pos1 + 9'd1;
                    y_pos2 <= y_pos2 + 9'd1;
                end
            end else if (up) begin
                if (y_pos1 <= 9'd150) begin
                    down   <= 1'b1;
                    up     <= 1'b0;
                    y_pos1 <= y_pos1 + 9'd1;
                    y_pos2 <= y_pos2 + 9'd1;
                end else begin
                    y_pos1 <= y_pos1 - 9'd1;
                    y_pos2 <= y_pos2 - 9'd1;
                end
            end

            // ball moves left and right only
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

endmodule