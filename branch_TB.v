`timescale 1ns/1ps

module lab4_full_TB;

    reg clk;
    reg reset; // active-low

    // -----------------------------
    // FSM <-> datapath wires
    // -----------------------------
    wire [15:0] wEnable;
    wire [7:0]  opcode;
    wire [3:0]  Rdest_select, Rsrc_select;
    wire [15:0] Imm_in;          // keep 16 here for datapath compatibility
    wire        Imm_select;

    wire we_a, en_a, en_b, ram_wen;
    wire lsc_mux_selct;

    // FSM outputs 8-bit k, datapath wants 16-bit
    wire [7:0]  pc_add_k_8;
    wire [15:0] pc_add_k_to_dp;
    wire        pc_mux_selct, pc_en;

    wire fsm_alu_mem_selct;
    wire decoder_en;

    wire [15:0] ram_out;
    wire [4:0]  Flags_out;

    wire [15:0] pc_count;

    // full reg visibility
    wire [15:0] r0, r1, r2, r3, r4, r5, r6, r7;
    wire [15:0] r8, r9, r10, r11, r12, r13, r14, r15;

    // ------------------------------------
    // choose program image
    // branch.hex usually exercises more of lab
    // ------------------------------------
    localparam MEMFILE = "branch.hex";
    // localparam MEMFILE = "load_store.hex";

    // optional sign extend for branch displacement into datapath
    // set to 0 if you want raw zero-extended behavior exactly as simple wiring
    localparam SIGN_EXTEND_PC_K = 1'b1;
    assign pc_add_k_to_dp = SIGN_EXTEND_PC_K ? {{8{pc_add_k_8[7]}}, pc_add_k_8}
                                             : {8'h00, pc_add_k_8};

    // -----------------------------
    // DUT pieces
    // -----------------------------
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

        .pc_add_k(pc_add_k_8),
        .pc_mux_selct(pc_mux_selct),
        .pc_en(pc_en),

        .fsm_alu_mem_selct(fsm_alu_mem_selct),
        .decoder_en(decoder_en)
    );

    data_path #(
        .DATA_FILE(MEMFILE)
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

        .pc_add_k(pc_add_k_to_dp),
        .pc_mux_selct(pc_mux_selct),
        .pc_en(pc_en),

        .ram_out(ram_out),
        .pc_count(pc_count),

        .fsm_alu_mem_selct(fsm_alu_mem_selct),
        .Rdest_select(Rdest_select),
        .Rsrc_select(Rsrc_select),
        .Imm_in(Imm_in),
        .Imm_select(Imm_select),

        .r0(r0),   .r1(r1),   .r2(r2),   .r3(r3),
        .r4(r4),   .r5(r5),   .r6(r6),   .r7(r7),
        .r8(r8),   .r9(r9),   .r10(r10), .r11(r11),
        .r12(r12), .r13(r13), .r14(r14), .r15(r15)
    );

    // -----------------------------
    // clock / reset
    // -----------------------------
    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end

    initial begin
        reset = 1'b0;
        repeat (3) @(posedge clk);
        reset = 1'b1;
    end

    // -----------------------------
    // waveform dump
    // -----------------------------
    initial begin
        $dumpfile("lab4_full_tb.vcd");
        $dumpvars(0, lab4_full_TB);
    end

    // -----------------------------
    // helpers
    // -----------------------------
    reg [8*12-1:0] state_str;
    always @(*) begin
        case (fsm.PS)
            3'd0: state_str = "FETCH";
            3'd1: state_str = "DECODE";
            3'd2: state_str = "EXEC";
            3'd3: state_str = "STORE";
            3'd4: state_str = "LOAD";
            3'd5: state_str = "DOUT";
            3'd6: state_str = "BRANCH";
            default: state_str = "?";
        endcase
    end

    function [8*12-1:0] instr_class_str;
        input [15:0] instr;
        begin
            casez (instr)
                16'b0100_????_0100_????: instr_class_str = "STORE";
                16'b0100_????_0000_????: instr_class_str = "LOAD";
                16'b1100_????_????_????: instr_class_str = "BRANCH";
                default: begin
                    if ({instr[15:12], instr[7:4]} == 8'h00)
                        instr_class_str = "WAIT";
                    else if (instr[15:12] == 4'h0)
                        instr_class_str = "R-TYPE";
                    else
                        instr_class_str = "I-TYPE";
                end
            endcase
        end
    endfunction

    function [8*10-1:0] opcode_str;
        input [7:0] op;
        begin
            case (op)
                8'h05: opcode_str = "ADD";
                8'h06: opcode_str = "ADDU";
                8'h07: opcode_str = "ADDC";
                8'h0D: opcode_str = "MOV";
                8'h0E: opcode_str = "MUL";
                8'h09: opcode_str = "SUB";
                8'h0A: opcode_str = "SUBC";
                8'h0B: opcode_str = "CMP";
                8'h01: opcode_str = "AND";
                8'h02: opcode_str = "OR";
                8'h03: opcode_str = "XOR";
                8'h04: opcode_str = "NOT";
                8'h8C: opcode_str = "LSH";
                8'h08: opcode_str = "RSH";
                8'h0F: opcode_str = "ARSH";

                8'h50: opcode_str = "ADDI";
                8'h60: opcode_str = "ADDUI";
                8'h70: opcode_str = "ADDCI";
                8'hD0: opcode_str = "MOVI";
                8'hE0: opcode_str = "MULI";
                8'h90: opcode_str = "SUBI";
                8'hA0: opcode_str = "SUBCI";
                8'hB0: opcode_str = "CMPI";
                8'h40: opcode_str = "LOAD";
                8'h44: opcode_str = "STOR";
                8'hC0: opcode_str = "BRANCH";
                8'h00: opcode_str = "WAIT";
                default: opcode_str = "OP?";
            endcase
        end
    endfunction

    task read_mem_word;
        input  [15:0] addr;
        output [15:0] data;
        begin
            if (addr[9] == 1'b0)
                data = dp.u_ram.bram0.ram[addr[8:0]];
            else
                data = dp.u_ram.bram1.ram[addr[8:0]];
        end
    endtask

    task print_regs_short;
        begin
            $display("    regs: r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
                     r0,r1,r2,r3,r4,r5,r6,r7);
            $display("          r8=%h r9=%h r10=%h r11=%h r12=%h r13=%h r14=%h r15=%h",
                     r8,r9,r10,r11,r12,r13,r14,r15);
        end
    endtask

    task print_summary;
        reg [15:0] m;
        integer i;
        begin
            $display("\n================ FINAL SUMMARY ================");
            $display("cycles=%0d", cyc);
            $display("state hits: FETCH=%0d DECODE=%0d EXEC=%0d STORE=%0d LOAD=%0d DOUT=%0d BRANCH=%0d",
                     hit_fetch, hit_decode, hit_exec, hit_store, hit_load, hit_dout, hit_branch);
            $display("events: reg_wb=%0d alu_wb=%0d load_wb=%0d stores=%0d branch_total=%0d branch_taken=%0d",
                     cnt_reg_wb, cnt_alu_wb, cnt_load_wb, cnt_store, cnt_branch, cnt_branch_taken);

            print_regs_short();

            $display("    nonzero mem[0..31] snapshot:");
            for (i = 0; i < 32; i = i + 1) begin
                read_mem_word(i[15:0], m);
                if (m !== 16'h0000)
                    $display("      mem[%0d / %h] = %h", i, i[15:0], m);
            end

            $display("===============================================\n");
        end
    endtask

    // -----------------------------
    // counters / tracking
    // -----------------------------
    integer cyc;
    integer cnt_reg_wb, cnt_alu_wb, cnt_load_wb, cnt_store, cnt_branch, cnt_branch_taken;
    integer hit_fetch, hit_decode, hit_exec, hit_store, hit_load, hit_dout, hit_branch;

    reg [2:0]  last_ps;
    reg [15:0] last_pc;
    reg [15:0] mem_now;
    reg [15:0] store_addr;
    reg [15:0] store_data;

    initial begin
        cyc = 0;
        cnt_reg_wb = 0;
        cnt_alu_wb = 0;
        cnt_load_wb = 0;
        cnt_store = 0;
        cnt_branch = 0;
        cnt_branch_taken = 0;

        hit_fetch = 0;
        hit_decode = 0;
        hit_exec = 0;
        hit_store = 0;
        hit_load = 0;
        hit_dout = 0;
        hit_branch = 0;

        last_ps = 3'bxxx;
        last_pc = 16'hxxxx;
    end

    // -----------------------------
    // main monitor
    // -----------------------------
    always @(posedge clk) begin
        cyc <= cyc + 1;

        if (!reset) begin
            $display("[%0t] reset=0", $time);
            last_ps <= fsm.PS;
            last_pc <= pc_count;
        end else begin
            // state coverage
            case (fsm.PS)
                3'd0: hit_fetch  <= hit_fetch + 1;
                3'd1: hit_decode <= hit_decode + 1;
                3'd2: hit_exec   <= hit_exec + 1;
                3'd3: hit_store  <= hit_store + 1;
                3'd4: hit_load   <= hit_load + 1;
                3'd5: hit_dout   <= hit_dout + 1;
                3'd6: hit_branch <= hit_branch + 1;
            endcase

            // cycle headline
            $display("[%0t] cyc=%0d  PS=%s  PC=%h  instr=%h  class=%s  op=%s",
                     $time, cyc, state_str, pc_count, ram_out, instr_class_str(ram_out), opcode_str(opcode));

            // signal/control detail
            $display("    ctrl: pc_en=%b pc_mux=%b pc_k8=%h lsc_mux=%b en_a=%b we_a=%b ram_wen=%b alu_mem_mux=%b imm_sel=%b dec_en=%b",
                     pc_en, pc_mux_selct, pc_add_k_8, lsc_mux_selct, en_a, we_a, ram_wen, fsm_alu_mem_selct, Imm_select, decoder_en);
            $display("    dec : Rdest=%0d Rsrc=%0d Imm=%h wEnable=%h Flags=%b  next_pc_path=%h",
                     Rdest_select, Rsrc_select, Imm_in, wEnable, Flags_out, dp.pc_in_wire);

            // register writeback event
            if (|wEnable) begin
                cnt_reg_wb <= cnt_reg_wb + 1;

                if (fsm.PS == 3'd5) begin
                    cnt_load_wb <= cnt_load_wb + 1;
                    $display("    LOAD-WB -> reg[%0d] <= mem_data=%h  (alu_bus=%h)",
                             Rsrc_select, dp.q_a_wire, dp.alu_bus);
                end else if (fsm.PS == 3'd2) begin
                    cnt_alu_wb <= cnt_alu_wb + 1;
                    $display("    ALU-WB  -> reg[%0d] <= alu_out=%h  (alu_bus=%h)",
                             Rdest_select, dp.alu_out, dp.alu_bus);
                end else begin
                    $display("    REG-WB  -> wEnable=%h  alu_bus=%h", wEnable, dp.alu_bus);
                end
            end

            // store event
            if (dp.mem_we) begin
                cnt_store <= cnt_store + 1;

                store_addr = dp.ls_cntrl;
                store_data = dp.Rsrc_mux_out;

                // wait a tiny amount so nonblocking RAM write lands
                #1;
                read_mem_word(store_addr, mem_now);

                $display("    STORE   -> mem[%h] <= %h   (mem_now=%h)", store_addr, store_data, mem_now);
            end

            // load read phase visibility
            if (fsm.PS == 3'd4) begin
                $display("    LOAD-ADR-> addr=%h  q_a_wire(now)=%h", dp.ls_cntrl, dp.q_a_wire);
            end

            // branch visibility
            if (fsm.PS == 3'd6) begin
                cnt_branch <= cnt_branch + 1;
                if (pc_mux_selct) cnt_branch_taken <= cnt_branch_taken + 1;

                $display("    BRANCH  -> cond=%h disp=%h flags=%b  taken=%b  pc_now=%h  pc_next_path=%h",
                         ram_out[11:8], ram_out[7:0], Flags_out, pc_mux_selct, pc_count, dp.pc_in_wire);
            end

            // compact reg snapshot each cycle
            $display("    regs    -> r0=%h r1=%h r2=%h r3=%h r4=%h r5=%h r6=%h r7=%h",
                     r0,r1,r2,r3,r4,r5,r6,r7);

            // state transition hint
            if (last_ps !== 3'bxxx && last_ps != fsm.PS) begin
                $display("    TRANS   -> %0d -> %0d", last_ps, fsm.PS);
            end

            last_ps <= fsm.PS;
            last_pc <= pc_count;
        end

        // timeout / stop
        if (cyc > 300) begin
            print_summary();
            $finish;
        end
    end

endmodule