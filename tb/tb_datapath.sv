// =============================================================
// tb_datapath.sv -- Testbench for the single-cycle datapath
//
// Program :
// 0x00  addi x1,x0,5
// 0x04  addi x2,x0,10
// 0x08  add  x3,x1,x2
// 0x0c  sw   x3,0(x0)
// 0x10  lw   x4,0(x0)
// 0x14  beq  x1,x2,48       # NOT taken
// 0x18  beq  x3,x4,+8       # TAKEN
// 0x1c  addi x5,x0,99       # [SKIPPED]
// 0x20  jal  x6,+8          # jumps to 0x28
// 0x24  addi x7,x0,77       # [SKIPPED]
// 0x28  addi x8,x0,55
// 0x2c  lui  x9,0x12345
// 0x30  auipc x10,0x1       # x10 = 0x30 + 0x1000 = 4144
// =============================================================

module tb_datapath;

    logic clk, reset;

    datapath dut (
        .clk   (clk),
        .reset (reset)
    );

    initial clk = 0;
    always #1 clk = ~clk;

    int errors = 0;


    task automatic step();
        @(negedge clk);
    endtask

    task automatic check_reg(input int idx, input [31:0] expected, input string name);
        logic [31:0] actual;
        actual = dut.u_register_file.registers[idx];
        if (actual !== expected) begin
            $display("FAIL [%s]: x%0d = %0d, expected %0d", name, idx, actual, expected);
            errors++;
        end else begin
            $display("PASS [%s]: x%0d = %0d", name, idx, actual);
        end
    endtask

    task automatic check_mem(input int word_idx, input [31:0] expected, input string name);
        logic [31:0] actual;
        actual = dut.u_d_mem.mem[word_idx];
        if (actual !== expected) begin
            $display("FAIL [%s]: mem[%0d] = %0d, expected %0d", name, word_idx, actual, expected);
            errors++;
        end else begin
            $display("PASS [%s]: mem[%0d] = %0d", name, word_idx, actual);
        end
    endtask

    task automatic check_pc(input [31:0] expected, input string name);
        if (dut.pc !== expected) begin
            $display("FAIL [%s]: pc = 0x%0h, expected 0x%0h", name, dut.pc, expected);
            errors++;
        end else begin
            $display("PASS [%s]: pc = 0x%0h", name, dut.pc);
        end
    endtask

    initial begin

        // initialize registers to 0
        for (int i = 0; i < 32; i++) begin
            dut.u_register_file.registers[i] = 32'd0;
        end

        reset = 1;
        step();
        reset = 0;

        // addi x1,x0,5 (0x00) 
        step();
        check_reg(1, 32'd5, "1: addi x1,x0,5");

        // addi x2,x0,10 (0x04) 
        step();
        check_reg(2, 32'd10, "2: addi x2,x0,10");

        // add x3,x1,x2 (0x08) 
        step();
        check_reg(3, 32'd15, "3: add x3,x1,x2");

        // sw x3,0(x0) (0x0c) 
        step();
        check_mem(0, 32'd15, "4: sw x3,0(x0)");

        // lw x4,0(x0) (0x10) 
        step();
        check_reg(4, 32'd15, "5: lw x4,0(x0)");

        // beq x1,x2,48 (0x14) 
        step();
        check_pc(32'h18, "6: beq x1,x2,48 (not taken, falls through to 0x18)");

        // beq x3,x4,+8 (0x18) 
        step();
        check_pc(32'h20, "7: beq x3,x4,+8 (taken, jumps to 0x20)");


        // jal x6,+8 (0x20) 
        step();
        check_reg(5, 32'd0, "0x1c: addi x5,x0,99 [SKIPPED, x5 must stay 0]");

        check_reg(6, 32'h24, "8: jal x6,+8 (x6 = 0x24)");
        check_pc(32'h28, "8: jal x6,+8 (jumps to 0x28)");


        // addi x8,x0,55 (0x28) 
        step();
        check_reg(7, 32'd0, "0x24: addi x7,x0,77 [SKIPPED, x7 must stay 0]");

        check_reg(8, 32'd55, "9: addi x8,x0,55");

        // lui x9,0x12345 (0x2c) 
        step();
        check_reg(9, 32'h12345000, "10: lui x9,0x12345");

        // auipc x10,0x1 (0x30) 
        step();
        check_reg(10, 32'h1030, "11: auipc x10,0x1 (x10 = 0x30 + 0x1000)");

        if (errors == 0)
            $display("\n=== ALL TESTS PASSED ===");
        else
            $display("\n=== %0d TEST(S) FAILED ===", errors);

        $stop;
    end

endmodule