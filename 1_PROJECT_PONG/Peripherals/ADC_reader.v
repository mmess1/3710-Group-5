module ADC_reader(
    input  wire       clk,
    input  wire       rst,
    input  wire [8:0] mcu_pot0,
    input  wire [8:0] mcu_pot1,
    output reg  [8:0] pot0_raw,
    output reg  [8:0] pot1_raw,
    output reg  [8:0] y_pos1,
    output reg  [8:0] y_pos2
);

    // Constants for paddle movement limits and scaling.
    localparam [8:0] Y_TOP         = 9'd10;
    localparam [8:0] PADDLE_HEIGHT = 9'd45;
    localparam [8:0] Y_BOTTOM      = 9'd470 - PADDLE_HEIGHT - 9'd10;
    localparam [8:0] Y_RANGE       = Y_BOTTOM - Y_TOP;
    localparam [8:0] POT_MAX       = 9'd511;

    // Synchronizer and inverted pot storage registers.
    reg [8:0] pot0_ff0;
    reg [8:0] pot0_ff1;
    reg [8:0] pot1_ff0;
    reg [8:0] pot1_ff1;

    reg [8:0] pot0_inv;
    reg [8:0] pot1_inv;

    // Map a 9-bit pot value into the legal paddle Y range.
    function [8:0] map_pot_to_y;
        input [8:0] raw;
        reg   [17:0] scaled_num;
        reg   [8:0]  scaled_y;
        reg   [8:0]  mapped_y;
        begin
            scaled_num = raw * Y_RANGE;
            scaled_y   = scaled_num / 9'd511;
            mapped_y   = Y_TOP + scaled_y;

            if (mapped_y < Y_TOP)
                map_pot_to_y = Y_TOP;
            else if (mapped_y > Y_BOTTOM)
                map_pot_to_y = Y_BOTTOM;
            else
                map_pot_to_y = mapped_y;
        end
    endfunction

    // Sample GPIO pot data invert it and update paddle positions.
    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            pot0_ff0 <= 9'd0;
            pot0_ff1 <= 9'd0;
            pot1_ff0 <= 9'd0;
            pot1_ff1 <= 9'd0;
            pot0_inv <= 9'd0;
            pot1_inv <= 9'd0;
            pot0_raw <= 9'd0;
            pot1_raw <= 9'd0;
            y_pos1   <= Y_TOP;
            y_pos2   <= Y_TOP;
        end else begin
            pot0_ff0 <= mcu_pot0;
            pot0_ff1 <= pot0_ff0;
            pot1_ff0 <= mcu_pot1;
            pot1_ff1 <= pot1_ff0;

            pot0_inv <= POT_MAX - pot0_ff1;
            pot1_inv <= POT_MAX - pot1_ff1;

            pot0_raw <= pot0_inv;
            pot1_raw <= pot1_inv;
            y_pos1   <= map_pot_to_y(pot0_inv);
            y_pos2   <= map_pot_to_y(pot1_inv);
        end
    end

endmodule