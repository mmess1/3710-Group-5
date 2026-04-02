module game_engine(
    input  wire       clk,
    input  wire       rst,
    input  wire [8:0] y_pos1_in,
    input  wire [8:0] y_pos2_in,
    output reg  [8:0] y_pos1,//r1
    output reg  [8:0] y_pos2,//r3
    output reg  [9:0] ball_x,//r6
    output reg  [9:0] ball_y,//r7
    output reg  [3:0] score1,//r4
    output reg  [3:0] score2 //r5
);

    // Tick rate constant for ball movement timing.
    localparam integer COUNT = 1_250_000;

    // Internal counter tick and direction registers.
    reg [20:0] counter;
    reg        tick;
    reg        direction;

    // Divide the 50 MHz clock down into a slower game tick.
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

    // Update paddle pass-through ball motion and score state.
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            y_pos1    <= 9'd415;
            y_pos2    <= 9'd415;
            ball_x    <= 10'd315;
            ball_y    <= 10'd235;
            score1    <= 4'd0;
            score2    <= 4'd0;
            direction <= 1'b0;
        end else begin
            y_pos1 <= y_pos1_in;
            y_pos2 <= y_pos2_in;

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