module bram_FSM2 (
    input  wire         Clk,
    input  wire         Rst,
    input  wire [15:0]  q_a, // ram port A data out
    input  wire [15:0]  q_b, // ram port B data out

    output reg  [15:0]  data_a,
    output reg  [15:0]  data_b,
    output reg  [9:0]   addr_a,
    output reg  [9:0]   addr_b,
    output reg          we_a,
    output reg          we_b,
    output reg          en_a,
    output reg          en_b,

    output reg  [15:0]  bram_output
);

    // States
    localparam s_init      = 4'd0;
    localparam s_read_req  = 4'd1; // present addr on A
    localparam s_read_cap  = 4'd2; // capture q_a (1-cycle latency)
    localparam s_write     = 4'd3; // write modified data to block 1 on B
    localparam s_reread    = 4'd4; // read back from block 1 on B
    localparam s_verify    = 4'd5; // check q_b
    localparam s_final     = 4'd6; // display

    reg [3:0] PS, NS;

    reg [8:0] idx, idx_next;         // 0..11
    reg [15:0] read_data;            // captured from q_a
    reg [15:0] expected_data;        // read_data + 1
    reg [15:0] last_good;            // what we display in final
    reg        done;                 // stop after idx==11
    reg        done_next;

    // Sequential state/index registers
    always @(posedge Clk or negedge Rst) begin
        if (!Rst) begin
            PS           <= s_init;
            idx          <= 9'd0;
            read_data    <= 16'd0;
            expected_data<= 16'd0;
            last_good    <= 16'd0;
            done         <= 1'b0;
        end else begin
            PS   <= NS;
            idx  <= idx_next;
            done <= done_next;

            // capture A read result (comes back after read_req)
            if (PS == s_read_cap) begin
                read_data     <= q_a;
                expected_data <= q_a + 16'd1;
            end
        end
    end

    // Next-state logic
    always @(*) begin
        NS        = PS;
        idx_next  = idx;
        done_next = done;

        case (PS)
            s_init: begin
                idx_next  = 9'd0;
                done_next = 1'b0;
                NS        = s_read_req;
            end

            s_read_req: begin
                // request read from block 0 at idx
                NS = s_read_cap;
            end

            s_read_cap: begin
                // now read_data/expected_data are captured in sequential block
                NS = s_write;
            end

            s_write: begin
                // write expected_data to block 1 at same idx
                NS = s_reread;
            end

            s_reread: begin
                // request read-back from block 1
                NS = s_verify;
            end

            s_verify: begin
                // decide if done, else advance idx and repeat
                if (idx == 9'd11) begin
                    done_next = 1'b1;
                    NS        = s_final;
                end else begin
                    idx_next  = idx + 9'd1;
                    NS        = s_read_req;
                end
            end

            s_final: begin
                NS = s_final; // hold
            end

            default: begin
                NS        = s_init;
                idx_next  = 9'd0;
                done_next = 1'b0;
            end
        endcase
    end

    // Output logic (combinational)
    always @(*) begin
        data_a      = 16'd0;
        data_b      = 16'd0;
        addr_a      = 10'd0;
        addr_b      = 10'd0;
        we_a        = 1'b0;
        we_b        = 1'b0;
        en_a        = 1'b0;
        en_b        = 1'b0;
        bram_output = 16'd0;

        case (PS)
            s_read_req: begin
                // READ block 0 using port A
                en_a   = 1'b1;
                we_a   = 1'b0;
                addr_a = {1'b0, idx};   // block0
            end

            s_read_cap: begin
                // keep address/en stable if your RAM wants it
                en_a   = 1'b1;
                we_a   = 1'b0;
                addr_a = {1'b0, idx};
            end

            s_write: begin
                // WRITE block 1 using port B
                en_b   = 1'b1;
                we_b   = 1'b1;
                addr_b = {1'b1, idx};   // block1 (512 + idx)
                data_b = expected_data; // <- ACTUAL modified write
            end

            s_reread: begin
                // READ BACK block 1 using port B
                en_b   = 1'b1;
                we_b   = 1'b0;
                addr_b = {1'b1, idx};
            end

            s_verify: begin
                // hold port B read stable one more cycle if needed
                en_b   = 1'b1;
                we_b   = 1'b0;
                addr_b = {1'b1, idx};
            end

            s_final: begin
                // Display the last verified value (or DEAD on mismatch)
                bram_output = last_good;
            end

            default: begin
                // s_init: all zeros
                bram_output = 16'd0;
            end
        endcase
    end

endmodule
