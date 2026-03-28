module ADC_reader(
    input  wire       clk,
    input  wire       rst,          // active low
    input  wire       ADC_DOUT,
    output reg        ADC_CS_N,
    output reg        ADC_DIN,
    output reg        ADC_SCLK,
    output reg [11:0] adc0_raw,
    output reg [11:0] adc1_raw,
    output reg        sample_strobe
);

    localparam [1:0] S_CONV  = 2'd0;
    localparam [1:0] S_WAIT  = 2'd1;
    localparam [1:0] S_LOW   = 2'd2;
    localparam [1:0] S_HIGH  = 2'd3;

    localparam integer HALF_DIV          = 25;
    localparam integer CONV_PULSE_CYCLES = 2;
    localparam integer CONV_WAIT_CYCLES  = 80;
    localparam integer TOTAL_BITS        = 12;

    reg [1:0]  state;
    reg [15:0] wait_cnt;
    reg [15:0] div_cnt;
    reg [3:0]  bit_cnt;

    reg [11:0] shift_in;
    reg [5:0]  shift_out;

    reg        next_chan;
    reg        result_chan;
    reg        have_valid;

    wire [11:0] sampled_word;

    assign sampled_word = {shift_in[10:0], ADC_DOUT};

    function [5:0] adc_cmd;
        input chan;
        begin
            adc_cmd = chan ? 6'b110010 : 6'b100010;
        end
    endfunction

    always @(posedge clk or negedge rst) begin
        if (~rst) begin
            ADC_CS_N      <= 1'b0;
            ADC_DIN       <= 1'b0;
            ADC_SCLK      <= 1'b0;

            adc0_raw      <= 12'd0;
            adc1_raw      <= 12'd0;
            sample_strobe <= 1'b0;

            state         <= S_CONV;
            wait_cnt      <= 16'd0;
            div_cnt       <= 16'd0;
            bit_cnt       <= 4'd0;
            shift_in      <= 12'd0;
            shift_out     <= 6'd0;

            next_chan     <= 1'b0;
            result_chan   <= 1'b0;
            have_valid    <= 1'b0;
        end else begin
            sample_strobe <= 1'b0;

            case (state)
                S_CONV: begin
                    ADC_CS_N <= 1'b1;
                    ADC_SCLK <= 1'b0;
                    ADC_DIN  <= 1'b0;

                    if (wait_cnt == CONV_PULSE_CYCLES - 1) begin
                        wait_cnt <= 16'd0;
                        ADC_CS_N <= 1'b0;
                        state    <= S_WAIT;
                    end else begin
                        wait_cnt <= wait_cnt + 16'd1;
                    end
                end

                S_WAIT: begin
                    ADC_CS_N <= 1'b0;
                    ADC_SCLK <= 1'b0;
                    ADC_DIN  <= 1'b0;

                    if (wait_cnt == CONV_WAIT_CYCLES - 1) begin
                        wait_cnt  <= 16'd0;
                        div_cnt   <= 16'd0;
                        bit_cnt   <= 4'd0;
                        shift_in  <= 12'd0;
                        shift_out <= adc_cmd(next_chan);
                        state     <= S_LOW;
                    end else begin
                        wait_cnt <= wait_cnt + 16'd1;
                    end
                end

                S_LOW: begin
                    ADC_CS_N <= 1'b0;
                    ADC_SCLK <= 1'b0;
                    ADC_DIN  <= (bit_cnt < 4'd6) ? shift_out[5] : 1'b0;

                    if (div_cnt == HALF_DIV - 1) begin
                        div_cnt  <= 16'd0;
                        ADC_SCLK <= 1'b1;
                        state    <= S_HIGH;
                    end else begin
                        div_cnt <= div_cnt + 16'd1;
                    end
                end

                S_HIGH: begin
                    ADC_CS_N <= 1'b0;
                    ADC_SCLK <= 1'b1;

                    if (div_cnt == (HALF_DIV/2)) begin
                        shift_in <= sampled_word;
                    end

                    if (div_cnt == HALF_DIV - 1) begin
                        div_cnt  <= 16'd0;
                        ADC_SCLK <= 1'b0;

                        if (bit_cnt < 4'd6)
                            shift_out <= {shift_out[4:0], 1'b0};

                        if (bit_cnt == TOTAL_BITS - 1) begin
                            if (have_valid) begin
                                if (result_chan == 1'b0)
                                    adc0_raw <= sampled_word;
                                else
                                    adc1_raw <= sampled_word;

                                sample_strobe <= 1'b1;
                            end

                            result_chan <= next_chan;
                            next_chan   <= ~next_chan;
                            have_valid  <= 1'b1;
                            state       <= S_CONV;
                        end else begin
                            bit_cnt <= bit_cnt + 4'd1;
                            state   <= S_LOW;
                        end
                    end else begin
                        div_cnt <= div_cnt + 16'd1;
                    end
                end

                default: begin
                    state <= S_CONV;
                end
            endcase
        end
    end

endmodule