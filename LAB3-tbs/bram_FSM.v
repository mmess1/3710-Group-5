module bram_FSM #(
                           parameter BIT_WIDTH    = 16,
                           parameter ADDR_WIDTH   = 10
                          )
                          (
                           input wire                           Clk,
                           input wire                           Rst,
                           input wire [BIT_WIDTH-1:0]           q_a,
                           input wire [BIT_WIDTH-1:0]           q_b,

                           output reg  [BIT_WIDTH-1:0]          data_a,
                           output reg  [BIT_WIDTH-1:0]          data_b,
                           output reg  [ADDR_WIDTH-1:0]         addr_a,
                           output reg  [ADDR_WIDTH-1:0]         addr_b,
                           output reg                           we_a,
                           output reg                           we_b,
                           output reg                           en_a,
                           output reg                           en_b,

                           output reg  [BIT_WIDTH-1:0]          bram_output
                          );

    localparam s_init  = 4'd0; // Initial state
    localparam s_1   = 4'd1;
    localparam s_2   = 4'd2;
    ...
    localparam s_final = 4'd3;

    reg [3:0] PS; // Present State
    reg [3:0] NS; // Next State

    // Init PS to the inital state or next state
    always @(posedge Clk, negedge Rst) begin
        if (~Rst)
            PS <= s_init;
        else
            PS <= NS;
    end

    // Set Next State
    always @(*) begin
        case (PS)
            s_init:  NS = s_1;
            s_1:   NS = s_2;
            s_2:   NS = s_final;
            s_final: NS = s_final;
            default: NS = s_init;
        endcase
    end

   // Set Outputs
    always @(*) begin
        data_a = 16'dx;
        data_b = 16'dx;
        addr_a = 10'dx;
        addr_b = 10'dx;
        we_a   = 1'b0;
        we_b   = 1'b0;
        en_a   = 1'b0;
        en_b   = 1'b0;

        bram_output = 16'dx;

        case (PS)

            // INIT
            s_init: begin
                data_a = 16'd0;
                data_b = 16'd0;
                addr_a = 10'd0;
                addr_b = 10'd0;
                we_a   = 1'b0;
                we_b   = 1'b0;
                en_a   = 1'b0;
                en_b   = 1'b0;

                bram_output = 16'd0;
            end

            s_1: begin
                en_a   = 1'b1;
                we_a   = 1'b0;
                addr_a = 10'd0;

                en_b   = 1'b0;
                we_b   = 1'b0;

                bram_output = q_a;
            end

            s_2: begin
                en_a   = 1'b1;
                we_a   = 1'b0;
                addr_a = 10'd0;

                en_b   = 1'b0;
                we_b   = 1'b0;

                bram_output = q_a;
            end

            ...

            // FINAL: hold
            s_final: begin
                data_a = 16'd0;
                data_b = 16'd0;
                addr_a = 10'd0;
                addr_b = 10'd0;
                we_a   = 1'b0;
                we_b   = 1'b0;
                en_a   = 1'b0;
                en_b   = 1'b0;

                bram_output = 16'd0;
            end

        endcase
    end

endmodule
