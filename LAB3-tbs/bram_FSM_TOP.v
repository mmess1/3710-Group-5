module bram_FSM_TOP #(
    parameter DATA_FILE0 = "C:/Users/mmess/3710-Group-5/fibb.hex",
    parameter DATA_FILE1 = ""
)(
    input  wire        CLOCK_50,
    input  wire [3:0]  KEY,
    input  wire [9:0]  SW,

    output wire [6:0]  HEX0,
    output wire [6:0]  HEX1,
    output wire [6:0]  HEX2,
    output wire [6:0]  HEX3
);

    wire Rst = KEY[0];

    wire [15:0] q_a, q_b;

    wire [15:0] f_data_a, f_data_b;
    wire [9:0]  f_addr_a, f_addr_b;
    wire        f_we_a, f_we_b, f_en_a, f_en_b;
    wire [15:0] f_bram_output;

    bram_FSM FSM (
        .Clk(CLOCK_50),
        .Rst(Rst),

        .q_a(q_a),
        .q_b(q_b),

        .data_a(f_data_a),
        .data_b(f_data_b),
        .addr_a(f_addr_a),
        .addr_b(f_addr_b),
        .we_a(f_we_a),
        .we_b(f_we_b),
        .en_a(f_en_a),
        .en_b(f_en_b),

        .bram_output(f_bram_output)
    );

    wire fsm_final_cond = f_en_a && ~f_we_a && ~f_en_b && ~f_we_b && f_addr_a[9];

    reg done;
    always @(posedge CLOCK_50 or negedge Rst) begin
        if (!Rst) done <= 1'b0;
        else if (fsm_final_cond) done <= 1'b1;
    end

    wire [15:0] mem_data_a = f_data_a;
    wire [9:0]  mem_addr_a = f_addr_a;
    wire        mem_we_a   = f_we_a;
    wire        mem_en_a   = f_en_a;

    wire [15:0] mem_data_b = done ? 16'd0 : f_data_b;
    wire [9:0]  mem_addr_b = done ? SW    : f_addr_b;
    wire        mem_we_b   = done ? 1'b0  : f_we_b;
    wire        mem_en_b   = done ? 1'b1  : f_en_b;

    ram #(
        .DATA_WIDTH(16),
        .ADDR_WIDTH(10),
        .DATA_FILE0(DATA_FILE0),
        .DATA_FILE1(DATA_FILE1)
    ) MEM (
        .data_a(mem_data_a), .data_b(mem_data_b),
        .addr_a(mem_addr_a), .addr_b(mem_addr_b),
        .we_a(mem_we_a),     .we_b(mem_we_b),
        .clk(CLOCK_50),
        .en_a(mem_en_a),     .en_b(mem_en_b),
        .q_a(q_a),           .q_b(q_b)
    );

    wire [15:0] disp = q_b;

    function [6:0] hex7;
        input [3:0] x;
        begin
            case (x)
                4'h0: hex7 = 7'b1000000;
                4'h1: hex7 = 7'b1111001;
                4'h2: hex7 = 7'b0100100;
                4'h3: hex7 = 7'b0110000;
                4'h4: hex7 = 7'b0011001;
                4'h5: hex7 = 7'b0010010;
                4'h6: hex7 = 7'b0000010;
                4'h7: hex7 = 7'b1111000;
                4'h8: hex7 = 7'b0000000;
                4'h9: hex7 = 7'b0010000;
                4'hA: hex7 = 7'b0001000;
                4'hB: hex7 = 7'b0000011;
                4'hC: hex7 = 7'b1000110;
                4'hD: hex7 = 7'b0100001;
                4'hE: hex7 = 7'b0000110;
                4'hF: hex7 = 7'b0001110;
                default: hex7 = 7'b1111111;
            endcase
        end
    endfunction

    assign HEX0 = hex7(disp[3:0]);
    assign HEX1 = hex7(disp[7:4]);
    assign HEX2 = hex7(disp[11:8]);
    assign HEX3 = hex7(disp[15:12]);

endmodule

/*







*/
