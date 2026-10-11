// =============================================================
// tb_datapath_pipeline.sv.
//
// Every expected value comes from a reference RV32I model that
// decodes the same machine code, and was cross-checked against
// hand-written expectations by the generator.
//
// Needs: I_mem DEPTH_WORDS >= 256, D_mem DEPTH_WORDS = 128.
//
// Result words (dmem word 32 onward) are written by the program
// itself with sw, so a wrong value anywhere shows up as one named
// FAIL. Coverage:
//   A  ALU->ALU forwarding: MEM source, WB source, both operands,
//      dependent chains, MEM-over-WB priority
//   B  x0: never forwarded, never written
//   C  loads/stores: store data fwd (MEM and WB), store base fwd,
//      load-use stall (rs1, rs2, store data, store base), load data
//      forwarded from WB (wb_data), lw 3 back via regfile, sw->lw
//      same address, spurious-stall regressions (imm / lui bits
//      equal to a load's rd), lw x0
//   D  load -> branch (stall, then fwd into comparator)
//   E  all six branch types, taken/not taken, signed/unsigned,
//      backward loop, wrong-path poison after every taken branch
//   F  jal, jalr (bit0 clear, rs1 fwd), call/return, chained jumps,
//      link value read by first instr at target (regfile bypass)
//   G  lui, auipc, every R-type and I-type ALU op
// =============================================================

module tb_datapath_pipeline;

    localparam int HALT_PC        = 656;   // address of the final jal x0,0
    localparam int EXP_STALLS     = 5;
    localparam int EXP_REDIRECTS  = 14;

    logic clk, reset;

    datapath_pipeline dut (.clk(clk), .reset(reset));

    initial clk = 0;
    always #1 clk = ~clk;

    int errors = 0;

    // Count only while real program instructions are in flight
    // (the halt loop redirects forever and must not be counted).
    int stall_count = 0, redirect_count = 0;
    always @(posedge clk) begin
        if (!reset && dut.stall === 1'b1 && dut.if_id.pc < HALT_PC) stall_count++;
        if (!reset && dut.ex_redirect_valid === 1'b1 && dut.id_ex.pc < HALT_PC) redirect_count++;
    end

    task automatic check_mem(input int widx, input [31:0] expected, input string name);
        logic [31:0] actual;
        actual = dut.u_d_mem.mem[widx];
        if (actual !== expected) begin
            $display("FAIL [%s]: mem[%0d] = 0x%08h, expected 0x%08h", name, widx, actual, expected);
            errors++;
        end else
            $display("PASS [%s]", name);
    endtask

    task automatic check_val(input [31:0] actual, input [31:0] expected, input string name);
        if (actual !== expected) begin
            $display("FAIL [%s]: %0d, expected %0d", name, actual, expected);
            errors++;
        end else
            $display("PASS [%s]: %0d", name, actual);
    endtask

    // watchdog
    initial begin
        #20000;
        $display("FAIL [timeout]: PC never reached halt loop (pc=0x%08h)", dut.pc);
        $finish;
    end

    initial begin
        for (int i = 0; i < 32; i++) dut.u_register_file.registers[i] = 32'd0;

        reset = 1;
        @(negedge clk);
        reset = 0;

        wait (dut.pc >= HALT_PC);
        repeat (10) @(posedge clk);       // drain the pipeline

        // ---- results the program stored for itself ----
        check_mem(32, 32'h0000000f, "A1 x3: rs1 WB-fwd, rs2 MEM-fwd");
        check_mem(33, 32'h0000001e, "A2 x4: both operands MEM-fwd");
        check_mem(34, 32'h00000019, "A3 x5: rs1 MEM-fwd, rs2 regfile");
        check_mem(35, 32'h00000003, "A4 x6: chain of dependent addi");
        check_mem(36, 32'h000000ca, "A5 x8: MEM-fwd has priority over WB (same rd)");
        check_mem(37, 32'h00000000, "B1 x0 never forwarded (rd=x0 in MEM)");
        check_mem(38, 32'h00000009, "B2 x0 operand plus forwarded operand");
        check_mem(39, 32'h00000000, "B3 x0 reads zero");
        check_mem(40, 32'h0000009a, "C1 load-use stall (both operands), then MEM-fwd of load data");
        check_mem(41, 32'h00000059, "C2 load result forwarded from WB stage (wb_data), no stall");
        check_mem(42, 32'h0000009a, "C3 load 3 back, read from regfile");
        check_mem(43, 32'h0000004e, "C4 store then load same address, then load-use");
        check_mem(44, 32'h0000004d, "C5 lw right after sw to same address");
        check_mem(45, 32'h0000001c, "C6 addi imm=28 matches rs2 field of lw x28: no stall");
        check_mem(46, 32'h000e0000, "C7 lui bits match rs1 field of lw x28: no stall");
        check_mem(47, 32'h00000000, "C8 lw x0 then use of x0: no stall, reads 0");
        check_mem(48, 32'h00000001, "E1 bne not taken, fall-through executed");
        check_mem(49, 32'h00000001, "E2 bltu not taken (unsigned compare)");
        check_mem(50, 32'h00000001, "E3 bge not taken (signed compare)");
        check_mem(51, 32'h00000001, "E4 blt not taken");
        check_mem(52, 32'h00000006, "E5 loop body ran 3 times (2 taken, 1 not taken)");
        check_mem(53, 32'h00000000, "E6 loop counter");
        check_mem(54, 32'h0000018c, "F1 jal link, read by first instr at target (regfile write-through)");
        check_mem(55, 32'h000001a0, "F2 jalr link, target bit0 cleared, rs1 MEM-fwd");
        check_mem(56, 32'h0000002a, "F3 call and return");
        check_mem(57, 32'h00000001, "F4 chained jumps");
        check_mem(58, 32'h12345678, "G1 lui+addi");
        check_mem(59, 32'h000011f0, "G2 auipc");
        check_mem(60, 32'hfffffffc, "G3 srai");
        check_mem(61, 32'h0000000f, "G4 srli");
        check_mem(62, 32'hffffffe0, "G5 slli");
        check_mem(63, 32'h00000001, "G6 slt");
        check_mem(64, 32'h00000000, "G7 sltu");
        check_mem(65, 32'h00000001, "G8 slti");
        check_mem(66, 32'h00000001, "G9 sltiu");
        check_mem(67, 32'hedcba987, "G10 xori");
        check_mem(68, 32'h00000078, "G11 andi");
        check_mem(69, 32'h00000555, "G12 ori");
        check_mem(70, 32'h00000008, "G13 sub");
        check_mem(71, 32'h12345670, "G14 add");
        check_mem(72, 32'h00040000, "G15 sll");
        check_mem(73, 32'h0001ffff, "G16 srl");
        check_mem(74, 32'hffffffff, "G17 sra");
        check_mem(75, 32'h00000000, "G18 xor");
        check_mem(76, 32'h00000000, "G19 and");
        check_mem(77, 32'hffffffff, "G20 or");

        // ---- raw data memory written directly by the program ----
        check_mem(0, 32'd77, "dmem[0] store with MEM-fwd data");
        check_mem(1, 32'd88, "dmem[1] store with WB-fwd data");
        check_mem(2, 32'd88, "dmem[2] store of load data after stall");
        check_mem(3, 32'd20, "dmem[3] pointer");
        check_mem(4, 32'd77, "dmem[4] store with MEM-fwd base address");
        check_mem(5, 32'd77, "dmem[5] store with load-forwarded base after stall");

        // ---- nothing from a squashed wrong path may commit ----
        check_val(dut.u_register_file.registers[31], 32'd0, "x31 poison never written (all flushes worked)");
        check_mem(127, 32'd0, "poison store never reached memory");
        check_val(dut.u_register_file.registers[0], 32'd0, "x0 still zero");

        // ---- hazard counts ----
        check_val(stall_count,    EXP_STALLS,    "load-use stall cycles (no spurious, none missing)");
        check_val(redirect_count, EXP_REDIRECTS, "taken branch + jump redirects");

        if (errors == 0) $display("\n=== ALL TESTS PASSED ===");
        else             $display("\n=== %0d TEST(S) FAILED ===", errors);
        $finish;
    end

endmodule