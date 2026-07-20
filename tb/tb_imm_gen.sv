module tb_imm_gen();
    import riscv_opcodes_pkg::*;


    logic[31:0] instruction;
    logic[31:0] imm_out;
    int errors = 0;

    imm_gen dut(

        .instruction(instruction),
        .imm_out(imm_out)
    );

    task automatic check(input  logic[31:0] expected , input string name);
        #1;
        if (imm_out != expected ) begin
        $display("FAILED %s: Expected = %h , Got = %h", name , expected , imm_out);
        end
        else begin
            $display("PASSED %s",name);  
        end 
    endtask

    initial begin
 
        // ------------------------------------------
        // I-type via load: lw x2, 8(x1)
        // ------------------------------------------
        instruction = {12'd8, 5'd1, 3'b010, 5'd2, OPC_LOAD};
        check(32'd8, "I-type lw, imm=+8");
 
        // ------------------------------------------
        // S-type: sw x2, 8(x1) 
        // ------------------------------------------
        instruction = {7'b0000000, 5'd2, 5'd1, 3'b010, 5'b01000, OPC_STORE};
        check(32'd8, "S-type sw, imm=+8");
 
        // ------------------------------------------     
        // S-type negative: sw x2, -4(x1)
        // ------------------------------------------
        instruction = {7'b1111111, 5'd2, 5'd1, 3'b010, 5'b11100, OPC_STORE};
        check(-32'sd4, "S-type sw, imm=-4");
 
        // ------------------------------------------
        // B-type: beq x1, x2, +8
        // ------------------------------------------
        instruction = {1'b0, 6'b000000, 5'd2, 5'd1, 3'b000, 4'b0100, 1'b0, OPC_BRANCH};
        check(32'd8, "B-type beq, imm=+8");
 
        // ------------------------------------------
        // B-type negative: beq x1, x2, -8
        // ------------------------------------------
        instruction = {1'b1, 6'b111111, 5'd2, 5'd1, 3'b000, 4'b1100, 1'b1, OPC_BRANCH};
        check(-32'sd8, "B-type beq, imm=-8");
 
        // ------------------------------------------
        // U-type: lui x1, 0x12345
        // ------------------------------------------
        instruction = {20'h12345, 5'd1, OPC_LUI};
        check(32'h12345000, "U-type lui, imm=0x12345000");
 
        // ------------------------------------------
        // J-type: jal x1, +16
        // ------------------------------------------
        instruction = {1'b0, 10'b0000001000, 1'b0, 8'b00000000, 5'd1, OPC_JAL};
        check(32'd16, "J-type jal, imm=+16");
 
        // ------------------------------------------
        // J-type negative: jal x1, -16
        // ------------------------------------------
        instruction = {1'b1, 10'b1111111000, 1'b1, 8'b11111111, 5'd1, OPC_JAL};
        check(-32'sd16, "J-type jal, imm=-16");
 
        // ------------------------------------------
        // R-type: add x1, x2, x3
        // ------------------------------------------
        instruction = {7'b0000000, 5'd3, 5'd2, 3'b000, 5'd1, OPC_OP};
        check(32'd0, "R-type add, no immediate");
 
        if (errors == 0)
            $display("\n=== ALL TESTS PASSED ===");
        else
            $display("\n=== %0d TEST(S) FAILED ===", errors);
 
        $stop;
    end 



endmodule
