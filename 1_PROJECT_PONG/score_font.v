module score_font(
    input  wire [3:0] digit,
    input  wire [2:0] row,
    input  wire [2:0] col,
    output reg        pixel_on
);

    reg [4:0] bits;

    always @(*) begin
        bits = 5'b00000;

        case (digit)
            4'd0: begin
                case (row)
                    3'd0: bits = 5'b11111;
                    3'd1: bits = 5'b10001;
                    3'd2: bits = 5'b10001;
                    3'd3: bits = 5'b10001;
                    3'd4: bits = 5'b11111;
                    default: bits = 5'b00000;
                endcase
            end

            4'd1: begin
                case (row)
                    3'd0: bits = 5'b00100;
                    3'd1: bits = 5'b01100;
                    3'd2: bits = 5'b00100;
                    3'd3: bits = 5'b00100;
                    3'd4: bits = 5'b01110;
                    default: bits = 5'b00000;
                endcase
            end

            4'd2: begin
                case (row)
                    3'd0: bits = 5'b11111;
                    3'd1: bits = 5'b00001;
                    3'd2: bits = 5'b11111;
                    3'd3: bits = 5'b10000;
                    3'd4: bits = 5'b11111;
                    default: bits = 5'b00000;
                endcase
            end

            4'd3: begin
                case (row)
                    3'd0: bits = 5'b11111;
                    3'd1: bits = 5'b00001;
                    3'd2: bits = 5'b01110;
                    3'd3: bits = 5'b00001;
                    3'd4: bits = 5'b11111;
                    default: bits = 5'b00000;
                endcase
            end

            4'd4: begin
                case (row)
                    3'd0: bits = 5'b10001;
                    3'd1: bits = 5'b10001;
                    3'd2: bits = 5'b11111;
                    3'd3: bits = 5'b00001;
                    3'd4: bits = 5'b00001;
                    default: bits = 5'b00000;
                endcase
            end

            4'd5: begin
                case (row)
                    3'd0: bits = 5'b11111;
                    3'd1: bits = 5'b10000;
                    3'd2: bits = 5'b11111;
                    3'd3: bits = 5'b00001;
                    3'd4: bits = 5'b11111;
                    default: bits = 5'b00000;
                endcase
            end

            4'd6: begin
                case (row)
                    3'd0: bits = 5'b11111;
                    3'd1: bits = 5'b10000;
                    3'd2: bits = 5'b11111;
                    3'd3: bits = 5'b10001;
                    3'd4: bits = 5'b11111;
                    default: bits = 5'b00000;
                endcase
            end

            4'd7: begin
                case (row)
                    3'd0: bits = 5'b11111;
                    3'd1: bits = 5'b00001;
                    3'd2: bits = 5'b00010;
                    3'd3: bits = 5'b00100;
                    3'd4: bits = 5'b00100;
                    default: bits = 5'b00000;
                endcase
            end

            4'd8: begin
                case (row)
                    3'd0: bits = 5'b11111;
                    3'd1: bits = 5'b10001;
                    3'd2: bits = 5'b11111;
                    3'd3: bits = 5'b10001;
                    3'd4: bits = 5'b11111;
                    default: bits = 5'b00000;
                endcase
            end

            4'd9: begin
                case (row)
                    3'd0: bits = 5'b11111;
                    3'd1: bits = 5'b10001;
                    3'd2: bits = 5'b11111;
                    3'd3: bits = 5'b00001;
                    3'd4: bits = 5'b11111;
                    default: bits = 5'b00000;
                endcase
            end

            default: bits = 5'b00000;
        endcase

        case (col)
            3'd0: pixel_on = bits[4];
            3'd1: pixel_on = bits[3];
            3'd2: pixel_on = bits[2];
            3'd3: pixel_on = bits[1];
            3'd4: pixel_on = bits[0];
            default: pixel_on = 1'b0;
        endcase
    end

endmodule