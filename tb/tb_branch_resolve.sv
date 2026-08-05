module tb_branch_resolve;

    logic [2:0]  funct3;
    logic [31:0] rs1, rs2;
    logic        branch_taken;

    int errors = 0;

    branch_resolve dut (
        .funct3       (funct3),
        .rs1          (rs1),
        .rs2          (rs2),
        .branch_taken (branch_taken)
    );

    task automatic check(input string name, input logic expected);
        #1;
        if (branch_taken !== expected) begin
            $display("FAIL [%s]: got %b, expected %b", name, branch_taken, expected);
            errors++;
        end else begin
            $display("PASS [%s]: branch_taken = %b", name, branch_taken);
        end
    endtask

    initial begin

        // beq
        funct3 = 3'b000; rs1 = 32'd5; rs2 = 32'd5;
        check("beq equal -> taken", 1'b1);
        rs1 = 32'd5; rs2 = 32'd6;
        check("beq not equal -> not taken", 1'b0);

        // bne
        funct3 = 3'b001; rs1 = 32'd5; rs2 = 32'd6;
        check("bne not equal -> taken", 1'b1);
        rs1 = 32'd5; rs2 = 32'd5;
        check("bne equal -> not taken", 1'b0);

        // blt
        funct3 = 3'b100; rs1 = -32'sd1; rs2 = 32'd1;
        check("blt -1 < 1 signed -> taken", 1'b1);
        rs1 = 32'd1; rs2 = -32'sd1;
        check("blt 1 < -1 signed -> not taken", 1'b0);

        // bge
        funct3 = 3'b101; rs1 = 32'd1; rs2 = -32'sd1;
        check("bge 1 >= -1 signed -> taken", 1'b1);
        rs1 = -32'sd1; rs2 = 32'd1;
        check("bge -1 >= 1 signed -> not taken", 1'b0);

        // bltu
        funct3 = 3'b110; rs1 = -32'sd1; rs2 = 32'd1;
        check("bltu 0xFFFFFFFF < 1 unsigned -> not taken", 1'b0);
        rs1 = 32'd1; rs2 = -32'sd1;
        check("bltu 1 < 0xFFFFFFFF unsigned -> taken", 1'b1);

        // bgeu
        funct3 = 3'b111; rs1 = -32'sd1; rs2 = 32'd1;
        check("bgeu 0xFFFFFFFF >= 1 unsigned -> taken", 1'b1);
        rs1 = 32'd1; rs2 = -32'sd1;
        check("bgeu 1 >= 0xFFFFFFFF unsigned -> not taken", 1'b0);

        if (errors == 0)
            $display("\n=== ALL TESTS PASSED ===");
        else
            $display("\n=== %0d TEST(S) FAILED ===", errors);

        $stop;
    end

endmodule