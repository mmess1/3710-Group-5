module ADC_reader(
    input  wire       clk,
    input  wire       rst,          // active low
    input  wire       ADC_DOUT,
    output reg        ADC_CS_N,
    output reg        ADC_DIN,
    output reg        ADC_SCLK,
    output reg [8:0]  y_pos1,
    output reg [8:0]  y_pos2,
    output reg        sample_strobe
);

    localparam [1:0] S_START = 2'd0;
    localparam [1:0] S_LOW   = 2'd1;
    localparam [1:0] S_HIGH  = 2'd2;
    localparam [1:0] S_DONE  = 2'd3;

    localparam integer HALF_DIV = 25;   // 50 MHz -> 1 MHz SCLK
    localparam integer BITS     = 16;

    localparam [8:0] Y_MIN         = 9'd10;
    localparam [8:0] PADDLE_HEIGHT = 9'd45;
    localparam [8:0] Y_MAX         = 9'd470 - PADDLE_HEIGHT - 9'd10;
    localparam [8:0] Y_RANGE       = Y_MAX - Y_MIN;

    // DE1-SoC manual says ADC full-scale is 0..4.096V.
    // If your pots are fed from 3.3V, practical max code is about 3299.
    localparam [11:0] ADC_MAX_3V3 = 12'd3299;

    reg [1:0]  state;
    reg [15:0] div_cnt;
    reg [4:0]  bit_cnt;

    reg [15:0] tx_word;
    reg [15:0] rx_word;

    reg        next_chan;
    reg        result_chan;
    reg        have_valid;

    wire [11:0] adc_code;

    assign adc_code = rx_word[15:4];

    function [7:0] adc_cmd_byte;
        input chan;
        begin
            // Left-aligned command byte form.
            // ch0 uses 0x88, ch1 uses 0xC8.
            adc_cmd_byte = chan ? 8'hC8 : 8'h88;
        end
    endfunction

    function [8:0] scale_adc;
        input [11:0] raw;
        reg   [11:0] clipped;
        begin
            clipped = (raw > ADC_MAX_3V3) ? ADC_MAX_3V3 : raw;
            scale_adc = Y_MIN + ((clipped * Y_RANGE) / ADC_MAX_3V3);
        end
    endfunction

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            ADC_CS_N      <= 1'b1;
            ADC_DIN       <= 1'b0;
            ADC_SCLK      <= 1'b0;

            y_pos1        <= 9'd150;
            y_pos2        <= 9'd150;
            sample_strobe <= 1'b0;

            state         <= S_START;
            div_cnt       <= 16'd0;
            bit_cnt       <= 5'd0;

            tx_word       <= 16'd0;
            rx_word       <= 16'd0;

            next_chan     <= 1'b0;
            result_chan   <= 1'b0;
            have_valid    <= 1'b0;
        end else begin
            sample_strobe <= 1'b0;

            case (state)
                S_START: begin
                    ADC_CS_N <= 1'b0;
                    ADC_SCLK <= 1'b0;
                    ADC_DIN  <= 1'b0;

                    div_cnt <= 16'd0;
                    bit_cnt <= 5'd0;
                    rx_word <= 16'd0;

                    tx_word <= {adc_cmd_byte(next_chan), 8'h00};
                    state   <= S_LOW;
                end

                S_LOW: begin
                    ADC_CS_N <= 1'b0;
                    ADC_SCLK <= 1'b0;
                    ADC_DIN  <= tx_word[15];

                    if (div_cnt == HALF_DIV - 1) begin
                        div_cnt   <= 16'd0;
                        ADC_SCLK  <= 1'b1;
                        state     <= S_HIGH;
                    end else begin
                        div_cnt <= div_cnt + 16'd1;
                    end
                end

                S_HIGH: begin
                    ADC_CS_N <= 1'b0;
                    ADC_SCLK <= 1'b1;

                    if (div_cnt == HALF_DIV - 1) begin
                        div_cnt  <= 16'd0;
                        ADC_SCLK <= 1'b0;

                        rx_word <= {rx_word[14:0], ADC_DOUT};
                        tx_word <= {tx_word[14:0], 1'b0};

                        if (bit_cnt == BITS - 1) begin
                            state <= S_DONE;
                        end else begin
                            bit_cnt <= bit_cnt + 5'd1;
                            state   <= S_LOW;
                        end
                    end else begin
                        div_cnt <= div_cnt + 16'd1;
                    end
                end

                S_DONE: begin
                    ADC_CS_N <= 1'b1;
                    ADC_SCLK <= 1'b0;
                    ADC_DIN  <= 1'b0;

                    if (have_valid) begin
                        if (result_chan == 1'b0)
                            y_pos1 <= scale_adc(adc_code);
                        else
                            y_pos2 <= scale_adc(adc_code);

                        sample_strobe <= 1'b1;
                    end

                    result_chan <= next_chan;
                    next_chan   <= ~next_chan;
                    have_valid  <= 1'b1;
                    state       <= S_START;
                end

                default: begin
                    state <= S_START;
                end
            endcase
        end
    end

endmodule