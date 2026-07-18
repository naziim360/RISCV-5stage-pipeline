module tb_regfile;

    logic clk;
    logic we;
    logic [4:0] rs1_addr, rs2_addr, rd_addr;
    logic [31:0] rs1_data, rs2_data,rd_data;

    int errors_counter = 0;

    regfile dut(
        .clk(clk),
        .we(we),
        .rs1_addr(rs1_addr),
        .rs2_addr(rs2_addr),
        .rd_addr(rd_addr),
        .rd_data(rd_data),
        .rs1_data(rs1_data),
        .rs2_data(rs2_data)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;


    task automatic write_and_check(
        input[4:0] addr,
        input[31:0] data,
        input logic expect_zero,
        input string name    
    );

    we=1'b1;
    rd_addr = addr;
    rd_data = data;
    
    rs1_addr=addr;

    @(posedge clk);
    #1;
    we=1'b0;

    if (expect_zero) begin
        if (rs1_data !== 32'd0) begin
            $display("FAIL [%s]: expected x0 to stay 0, got %0d", name, rs1_data);
            errors_counter++;
        end else begin
            $display("PASS [%s]: x0 correctly stayed 0", name);
        end

    end else begin
        if (rs1_data !== data) begin
            $display("FAIL [%s]: wrote %0d to x%0d, read back %0d",
                        name, data, addr, rs1_data);
            errors_counter++;
        end else begin
            $display("PASS [%s]: wrote %0d to x%0d, read back %0d correctly",
                        name, data, addr, rs1_data);
        end
    end
    endtask

    initial begin 

        we=1'b0;
        rs1_addr  = 5'b0;
        rs2_addr  = 5'b0;
        rd_addr   = 5'b0;
        rd_data   = 32'b0;
 
        // test 1: write 42 into x5, read back same cycle after the write
        write_and_check(5'd5, 32'd42, 1'b0, "write x5=42");
 
        // test 2: write a different value into x10
        write_and_check(5'd10, 32'hDEADBEEF, 1'b0, "write x10=0xDEADBEEF");
 
        // test 3: attempt to write into x0 -- must stay 0
        write_and_check(5'd0, 32'hFFFFFFFF, 1'b1, "attempt write x0");
 
        // test 4: dual-port read check -- read x5 and x10 simultaneously
        rs1_addr = 5'd5;
        rs2_addr = 5'd10;
        //#1;
        if (rs1_data !== 32'd42 || rs2_data !== 32'hDEADBEEF) begin
            $display("FAIL [dual read]: rs1=%0d rs2=%0h (expected 42 / DEADBEEF)",
                      rs1_data, rs2_data);
            errors_counter++;
        end else begin
            $display("PASS [dual read]: rs1=x5=%0d, rs2=x10=%0h correct simultaneously",
                      rs1_data, rs2_data);
        end
 
        // test 5: reg_write=0 should NOT modify the register even with
        // valid rd_addr/rd_data driven
        we = 1'b0;
        rd_addr   = 5'd5;
        rd_data   = 32'd999;
        @(posedge clk);
        //#1;
        rs1_addr = 5'd5;
        //#1;
        if (rs1_data !== 32'd42) begin
            $display("FAIL [write disabled]: x5 changed to %0d despite reg_write=0", rs1_data);
            errors_counter++;
        end else begin
            $display("PASS [write disabled]: x5 correctly unchanged (still 42)");
        end
 
        if (errors_counter == 0)
            $display("\n=== ALL TESTS PASSED ===");
        else
            $display("\n=== %0d TEST(S) FAILED ===", errors_counter);
 
        $stop;
    end        


endmodule