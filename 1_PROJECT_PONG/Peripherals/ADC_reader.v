module ADC_reader(
    input  wire       clk,
    input  wire       rst,
    input  wire       ADC_DOUT,
    output reg        ADC_CS_N,
    output reg        ADC_DIN,
    output reg        ADC_SCLK,
    output reg [11:0] adc0_raw,
    output reg [11:0] adc1_raw,
    output reg        sample_strobe
);

    localparam CONV  = 2'd0;
    localparam WAIT  = 2'd1;
    localparam LOW   = 2'd2;
    localparam HIGH  = 2'd3;

    localparam HALF_DIV  = 25;
    localparam CONV_PULSE = 2;
    localparam CONV_WAIT  = 80;
    localparam BITS       = 12;

    reg [1:0]  state;
    reg [15:0] wait_cnt;
    reg [15:0] div_cnt;
    reg [3:0]  bit_cnt;

    reg [11:0] shift_in;
    reg [5:0]  cmd_bits;

    reg next_chan;
    reg out_chan;
    reg valid;

    wire [11:0] sample_now;
    assign sample_now = {shift_in[10:0], ADC_DOUT};

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            state         <= CONV;
            wait_cnt      <= 0;
            div_cnt       <= 0;
            bit_cnt       <= 0;
            shift_in      <= 0;
            cmd_bits      <= 0;
            next_chan     <= 0;
            out_chan      <= 0;
            valid         <= 0;

            ADC_CS_N      <= 0;
            ADC_DIN       <= 0;
            ADC_SCLK      <= 0;
            adc0_raw      <= 0;
            adc1_raw      <= 0;
            sample_strobe <= 0;
        end else begin
            sample_strobe <= 0;

            case (state)
                CONV: begin
                    ADC_CS_N <= 1;
                    ADC_SCLK <= 0;
                    ADC_DIN  <= 0;

                    if (wait_cnt == CONV_PULSE - 1) begin
                        wait_cnt <= 0;
                        ADC_CS_N <= 0;
                        state    <= WAIT;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end

                WAIT: begin
                    ADC_CS_N <= 0;
                    ADC_SCLK <= 0;
                    ADC_DIN  <= 0;

                    if (wait_cnt == CONV_WAIT - 1) begin
                        wait_cnt <= 0;
                        div_cnt  <= 0;
                        bit_cnt  <= 0;
                        shift_in <= 0;
                        cmd_bits <= next_chan ? 6'b110010 : 6'b100010;
                        state    <= LOW;
                    end else begin
                        wait_cnt <= wait_cnt + 1;
                    end
                end

                LOW: begin
                    ADC_CS_N <= 0;
                    ADC_SCLK <= 0;
                    ADC_DIN  <= (bit_cnt < 6) ? cmd_bits[5] : 0;

                    if (div_cnt == HALF_DIV - 1) begin
                        div_cnt  <= 0;
                        ADC_SCLK <= 1;
                        state    <= HIGH;
                    end else begin
                        div_cnt <= div_cnt + 1;
                    end
                end

                HIGH: begin
                    ADC_CS_N <= 0;
                    ADC_SCLK <= 1;

                    if (div_cnt == HALF_DIV/2)
                        shift_in <= sample_now;

                    if (div_cnt == HALF_DIV - 1) begin
                        div_cnt  <= 0;
                        ADC_SCLK <= 0;

                        if (bit_cnt < 6)
                            cmd_bits <= {cmd_bits[4:0], 1'b0};

                        if (bit_cnt == BITS - 1) begin
                            if (valid) begin
                                if (out_chan == 0)
                                    adc0_raw <= sample_now;
                                else
                                    adc1_raw <= sample_now;
                                sample_strobe <= 1;
                            end

                            out_chan   <= next_chan;
                            next_chan  <= ~next_chan;
                            valid      <= 1;
                            state      <= CONV;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                            state   <= LOW;
                        end
                    end else begin
                        div_cnt <= div_cnt + 1;
                    end
                end
            endcase
        end
    end

endmodule