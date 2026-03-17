module movement
#(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 16
)
(
    input  wire                    clk,
    input  wire                    rst,
    input  wire [(DATA_WIDTH-1):0] data_in,
    output reg  [(ADDR_WIDTH-1):0] addr,
    output reg  [(DATA_WIDTH-1):0] data_out,
    output reg                     we
);

// Smooth movement settings.
// At a 25 MHz pixel clock, COUNT=833333 gives one movement burst about every 33 ms.
// That is about 30 position updates per second.
localparam COUNT      = 32'd833333;
localparam STATE_ITER = 32'd5;
wire timer;

pulse pwm (
    .clk(clk),
    .rst(rst),
    .length1(STATE_ITER),
    .length2(COUNT),
    .pulse(timer)
);

localparam FETCH_X = 3'd0;
localparam SAVE_X  = 3'd1;
localparam FETCH_Y = 3'd2;
localparam SAVE_Y  = 3'd3;
localparam FETCH_M = 3'd4;
localparam SAVE_M  = 3'd5;

reg [2:0] PS, NS;

localparam SCREEN_WIDTH  = 16'd640;
localparam SCREEN_HEIGHT = 16'd480;
localparam GLYPH_WIDTH   = 16'd48;
localparam GLYPH_HEIGHT  = 16'd48;
localparam X_MIN         = 16'd0;
localparam Y_MIN         = 16'd0;
localparam X_MAX         = SCREEN_WIDTH  - GLYPH_WIDTH;   // 592
localparam Y_MAX         = SCREEN_HEIGHT - GLYPH_HEIGHT;  // 432
localparam X_STEP        = 16'd1;
localparam Y_STEP        = 16'd1;

// Use only three frames from glyphs.hex: frame 0, 1, 2.
localparam LAST_FRAME      = 16'd2;

// With ~30 movement updates per second, 90 updates is about 3 seconds.
localparam MOVES_PER_FRAME = 7'd90;

// 1 = positive direction, 0 = negative direction
reg       x_dir_in, x_dir_out;
reg       y_dir_in, y_dir_out;
reg [6:0] anim_wait_in, anim_wait_out;

always @(posedge clk or negedge rst) begin
    if (~rst) begin
        x_dir_out     <= 1'b1;
        y_dir_out     <= 1'b1;
        anim_wait_out <= 7'd0;
    end
    else begin
        x_dir_out     <= x_dir_in;
        y_dir_out     <= y_dir_in;
        anim_wait_out <= anim_wait_in;
    end
end

always @(posedge clk or negedge rst) begin
    if (~rst)
        PS <= FETCH_X;
    else if (timer)
        PS <= NS;
end

always @* begin
    addr         = {ADDR_WIDTH{1'b0}};
    data_out     = {DATA_WIDTH{1'b0}};
    we           = 1'b0;
    NS           = PS;
    x_dir_in     = x_dir_out;
    y_dir_in     = y_dir_out;
    anim_wait_in = anim_wait_out;

    case (PS)
        FETCH_X: begin
            addr = 16'h1000;
            NS   = SAVE_X;
        end

        SAVE_X: begin
            addr = 16'h1000;
            we   = 1'b1;

            if (x_dir_out) begin
                if (data_in >= (X_MAX - X_STEP)) begin
                    data_out = X_MAX;
                    x_dir_in = 1'b0;
                end
                else begin
                    data_out = data_in + X_STEP;
                end
            end
            else begin
                if (data_in <= (X_MIN + X_STEP)) begin
                    data_out = X_MIN;
                    x_dir_in = 1'b1;
                end
                else begin
                    data_out = data_in - X_STEP;
                end
            end

            NS = FETCH_Y;
        end

        FETCH_Y: begin
            addr = 16'h1001;
            NS   = SAVE_Y;
        end

        SAVE_Y: begin
            addr = 16'h1001;
            we   = 1'b1;

            if (y_dir_out) begin
                if (data_in >= (Y_MAX - Y_STEP)) begin
                    data_out = Y_MAX;
                    y_dir_in = 1'b0;
                end
                else begin
                    data_out = data_in + Y_STEP;
                end
            end
            else begin
                if (data_in <= (Y_MIN + Y_STEP)) begin
                    data_out = Y_MIN;
                    y_dir_in = 1'b1;
                end
                else begin
                    data_out = data_in - Y_STEP;
                end
            end

            NS = FETCH_M;
        end

        FETCH_M: begin
            addr = 16'h1002;
            NS   = SAVE_M;
        end

        // Position still updates smoothly every movement burst,
        // but the animation frame changes only once every ~3 seconds.
        SAVE_M: begin
            addr = 16'h1002;
            we   = 1'b1;

            if (anim_wait_out >= (MOVES_PER_FRAME - 1'b1)) begin
                anim_wait_in = 7'd0;

                if (data_in >= LAST_FRAME)
                    data_out = {DATA_WIDTH{1'b0}};
                else
                    data_out = data_in + 16'd1;
            end
            else begin
                anim_wait_in = anim_wait_out + 7'd1;
                data_out     = data_in;
            end

            NS = FETCH_X;
        end

        default: begin
            NS = FETCH_X;
        end
    endcase
end

endmodule
