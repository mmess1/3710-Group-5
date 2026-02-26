`timescale 1ns/1ps

module load_store_TB;

    reg clk;
    reg reset; // active-low

    // FSM <-> datapath wires (only what we need + required ports)
    wire [15:0] wEnable;
    wire [7:0]  opcode;
    wire [3:0]  Rdest_select, Rsrc_select;
    wire [15:0] Imm_in;
    wire        Imm_select;

    wire we_a, en_a, en_b, ram_wen;
    wire lsc_mux_selct;

    wire [15:0] pc_add_k;
    wire pc_mux_selct, pc_en;

    wire fsm_alu_mem_selct;
    wire decoder_en;

    wire [15:0] ram_out;
    wire [4:0]  Flags_out;

    wire [15:0] pc_count;

    // was r0,r1 only
    wire [15:0] r0, r1, r2, r3, r4, r5;

    localparam MEMFILE = "load_store.hex";

    load_store_FSM fsm(
        .clk(clk),
        .reset(reset),

        .instr_set(ram_out),
        .Flags_in(Flags_out),

        .wEnable(wEnable),

        .opcode(opcode),
        .Rdest_select(Rdest_select),
        .Rsrc_select(Rsrc_select),
        .Imm_in(Imm_in),
        .Imm_select(Imm_select),

        .we_a(we_a),
        .en_a(en_a),
        .en_b(en_b),
        .ram_wen(ram_wen),

        .lsc_mux_selct(lsc_mux_selct),

        .pc_add_k(pc_add_k),
        .pc_mux_selct(pc_mux_selct),
        .pc_en(pc_en),

        .fsm_alu_mem_selct(fsm_alu_mem_selct),
        .decoder_en(decoder_en)
    );

    data_path #(
        .bram1text(MEMFILE)
    ) dp(
        .clk(clk),
        .reset(reset),
        .ram_we(ram_wen),

        .wEnable(wEnable),

        .opcode(opcode),
        .Flags_out(Flags_out),

        .we_a(we_a),
        .en_a(en_a),
        .en_b(en_b),

        .lsc_mux_selct(lsc_mux_selct),

        .pc_add_k(pc_add_k),
        .pc_mux_selct(pc_mux_selct),
        .pc_en(pc_en),

        .ram_out(ram_out),
        .pc_count(pc_count),

        .fsm_alu_mem_selct(fsm_alu_mem_selct),
        .Rdest_select(Rdest_select),
        .Rsrc_select(Rsrc_select),
        .Imm_in(Imm_in),
        .Imm_select(Imm_select),

        .r0(r0),
        .r1(r1),
        .r2(r2),
        .r3(r3),
        .r4(r4),
        .r5(r5)

        // all other reg outputs intentionally left unconnected
    );

    // clock
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    // reset (active-low)
    initial begin
        reset = 1'b0;
        repeat (3) @(posedge clk);
        reset = 1'b1;
    end

    // dump
    initial begin
        $dumpfile("load_store_min.vcd");
        $dumpvars(0, load_store_TB);
    end

    // state string (only thing we show)
    reg [79:0] state_str;
    always @(*) begin
        case (fsm.PS)
            3'd0: state_str = "FETCH";
            3'd1: state_str = "DECODE";
            3'd2: state_str = "EXEC";
            3'd3: state_str = "STORE";
            3'd4: state_str = "LOAD";
            3'd5: state_str = "DOUT";
            default: state_str = "?";
        endcase
    end

    integer cyc;
    reg [15:0] mem_now;
    reg [15:0] store_addr;
    reg [15:0] store_data;

    initial cyc = 0;

    always @(posedge clk) begin
        cyc <= cyc + 1;

        if (!reset) begin
            $display("[%0t] reset=0", $time);
        end else begin
            // state, PC, r0..r5
            $display("[%0t] cyc=%0d  PC=%h  state=%s  r0=%h  r1=%h  r2=%h  r3=%h  r4=%h  r5=%h",
                     $time, cyc, pc_count, state_str, r0, r1, r2, r3, r4, r5);
        end

        // ONLY log STOREs + show the memory cell written
        if (reset && dp.mem_we) begin
            store_addr = dp.ls_cntrl;
            store_data = dp.Rsrc_mux_out;

            // wait a tiny delta so the nonblocking write lands in bram.ram[]
            #1;
            if (store_addr[9] == 1'b0)
                mem_now = dp.u_ram.bram0.ram[store_addr[8:0]];
            else
                mem_now = dp.u_ram.bram1.ram[store_addr[8:0]];

            $display("    STORE -> mem[%h] = %h   (mem_now=%h)", store_addr, store_data, mem_now);
        end

        if (cyc > 200) $finish;
    end

endmodule
