module game_engine(
    input  wire       clk,
    input  wire       rst,       // active low
    output reg [9:0]  ball_x,
    output reg [9:0]  ball_y,
    output reg [3:0]  score1,
    output reg [3:0]  score2
);

    localparam integer COUNT = 1_250_000;

    reg [20:0] counter;
    reg        tick;
    reg        direction;

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
            ball_x    <= 10'd315;
            ball_y    <= 10'd235;
            score1    <= 4'd0;
            score2    <= 4'd0;
            direction <= 1'b0;
        end else if (tick) begin
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