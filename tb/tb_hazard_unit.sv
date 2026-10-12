module tb_hazard_unit;

    logic        id_ex_mem_read;
    logic [4:0]  id_ex_rd_addr, id_rs1_addr, id_rs2_addr;
    logic        id_uses_rs1, id_uses_rs2;
    logic        stall;

    int errors = 0;

    hazard_unit dut (
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_rd_addr  (id_ex_rd_addr),
        .id_rs1_addr    (id_rs1_addr),
        .id_rs2_addr    (id_rs2_addr),
        .id_uses_rs1    (id_uses_rs1),
        .id_uses_rs2    (id_uses_rs2),
        .stall          (stall)
    );

    task automatic check(
        input string name,
        input logic  mem_read,
        input [4:0]  ld_rd,
        input [4:0]  rs1,
        input [4:0]  rs2,
        input logic  u1,
        input logic  u2,
        input logic  expected
    );
        id_ex_mem_read = mem_read;
        id_ex_rd_addr  = ld_rd;
        id_rs1_addr    = rs1;
        id_rs2_addr    = rs2;
        id_uses_rs1    = u1;
        id_uses_rs2    = u2;
        #1;
        if (stall !== expected) begin
            $display("FAIL [%s]: stall=%b, expected %b", name, stall, expected);
            errors++;
        end else begin
            $display("PASS [%s]: stall=%b", name, stall);
        end
    endtask

    initial begin
        check("load-use on rs1",                         1,   5'd4, 5'd4, 5'd9, 1, 1, 1);
        check("load-use on rs2",                         1,   5'd4, 5'd9, 5'd4, 1, 1, 1);
        check("load-use on both (add x5,x4,x4)",         1,   5'd4, 5'd4, 5'd4, 1, 1, 1);
        check("no match -> no stall",                    1,   5'd4, 5'd1, 5'd2, 1, 1, 0);
        check("EX instr is not a load -> no stall",      0,   5'd4, 5'd4, 5'd4, 1, 1, 0);
        check("load into x0 -> no stall",                1,   5'd0, 5'd0, 5'd0, 1, 1, 0);

        // addi x11,x0,10 : rs2 field bits = 01010 = 10 (immediate bits!)
        // preceded by lw x10,... -> rd=10. rs2 field matches but the
        // instruction does not read rs2 -> must NOT stall.
        check("I-type imm bits mimic load rd (no stall)",1,   5'd10, 5'd0, 5'd10, 1, 0, 0);

        // same bits, but an instruction that really uses rs2 -> stall
        check("R-type really reads rs2 -> stall",        1,   5'd10, 5'd0, 5'd10, 1, 1, 1);

        // lui/auipc/jal: [19:15] belongs to the immediate
        check("lui: rs1 bits are immediate (no stall)",  1,   5'd7,  5'd7, 5'd0,  0, 0, 0);

        // I-type that genuinely reads rs1 still stalls on rs1
        check("I-type real rs1 dependency -> stall",     1,   5'd4,  5'd4, 5'd0,  1, 0, 1);

        if (errors == 0)
            $display("\n=== ALL TESTS PASSED ===");
        else
            $display("\n=== %0d TEST(S) FAILED ===", errors);

        $stop;
    end

endmodule