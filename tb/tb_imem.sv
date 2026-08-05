module tb_imem;

    logic [31:0] addr;
    logic [31:0] instr;

    int errors = 0;

    I_mem #(
        .DEPTH_WORDS (16),
        .INIT_FILE   ("../asm/tb_imem_test.mem")
    ) dut (
        .addr  (addr),
        .instr (instr)
    );

    task automatic check(input [31:0] byte_addr, input [31:0] expected, input string name);
        addr = byte_addr;
        #1;
        if (instr !== expected) begin
            $display("FAIL [%s]: addr=0x%0h -> got 0x%0h, expected 0x%0h",
                       name, byte_addr, instr, expected);
            errors++;
        end else begin
            $display("PASS [%s]: addr=0x%0h -> instr=0x%0h", name, byte_addr, instr);
        end
    endtask

    initial begin
        check(32'h0, 32'h00500093, "word 0");
        check(32'h4, 32'h00A00113, "word 1");
        check(32'h8, 32'h002081B3, "word 2");


        if (errors == 0)
            $display("\n=== ALL TESTS PASSED ===");
        else
            $display("\n=== %0d TEST(S) FAILED ===", errors);

        $stop;
    end

endmodule