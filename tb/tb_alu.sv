module tb_alu;
    import alu_pkg::*;
    logic [31:0] op_a, op_b;
    alu_op_t alu_op;
    logic [31:0] result;
    logic zero;

    int errors_counter = 0;

    alu dut(
        .alu_a (op_a),
        .alu_b (op_b),
        .alu_op (alu_op),
        .alu_result (result),
        .alu_flag_zero (zero)
    );

    task automatic tester(
        input [31:0] a,
        input [31:0] b,
        alu_op_t op,
        input [31:0] expected_result,
        string name
    );

        op_a = a;
        op_b = b;
        alu_op = op;
        #10;

        if (result != expected_result) begin
            $display("FAIL [%s] : a=%0d b=%0d gives %0d, instead of %0d",
                     name, $signed(a), $signed(b), $signed(result), $signed(expected_result));
            errors_counter++;
        end else begin
            $display("PASS [%s]: result = %0d", name, $signed(result));
        end
    endtask

    initial begin
        tester(32'd5,  32'd3,  ALU_ADD,  32'd8,          "ADD  5+3");
        tester(32'd5,  32'd3,  ALU_SUB,  32'd2,          "SUB  5-3");
        tester(32'hFF, 32'h0F, ALU_AND,  32'h0F,         "AND");
        tester(32'hF0, 32'h0F, ALU_OR,   32'hFF,         "OR");
        tester(32'hFF, 32'h0F, ALU_XOR,  32'hF0,         "XOR");
        tester(32'd1,  32'd4,  ALU_SLL,  32'd16,         "SLL  1<<4");
        tester(32'd16, 32'd4,  ALU_SRL,  32'd1,          "SRL  16>>4");
        tester(-32'sd8, 32'd1, ALU_SRA,  -32'sd4,        "SRA  -8>>>1");
        tester(-32'sd1, 32'd1, ALU_SLT,  32'd1,          "SLT  -1<1 signed");
        tester(32'd1,  -32'sd1,ALU_SLTU, 32'd1,          "SLTU 1<0xFFFFFFFF unsigned");
        tester(32'd5,  32'd5,  ALU_SUB,  32'd0,          "SUB  5-5 (zero flag test)");


        if (zero == 1'b0) begin
            $display("FAIL [zero flag]: expected zero=1 after 5-5");
            errors_counter++;
        end else begin
            $display("PASS [zero flag]: correctly asserted after 5-5");
        end

        if (errors_counter == 0) begin
            $display("All tests passed!");
        end else begin
            $display("%d tests failed", errors_counter);
            $stop;
        end
    end
endmodule