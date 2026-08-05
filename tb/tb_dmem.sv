module tb_dmem;

    logic        clk;
    logic        mem_read, mem_write;
    logic [31:0] addr, write_data, read_data;

    int errors = 0;

    D_mem #(
        .DEPTH_WORDS (16),
        .PRELOAD     (1'b0)
    ) dut (
        .clk        (clk),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .addr       (addr),
        .write_data (write_data),
        .read_data  (read_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic write_word(input [31:0] a, input [31:0] d);
        mem_write  = 1'b1;
        addr       = a;
        write_data = d;
        @(posedge clk);
        #1;
        mem_write = 1'b0;
    endtask

    task automatic check_read(input [31:0] a, input [31:0] expected, input string name);
        addr = a;
        #1;
        if (read_data !== expected) begin
            $display("FAIL [%s]: addr=0x%0h -> got 0x%0h, expected 0x%0h",
                       name, a, read_data, expected);
            errors++;
        end else begin
            $display("PASS [%s]: addr=0x%0h -> read_data=0x%0h", name, a, read_data);
        end
    endtask

    initial begin
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        addr       = 32'd0;
        write_data = 32'd0;

        // write then read back word 0
        write_word(32'h0, 32'hDEADBEEF);
        check_read(32'h0, 32'hDEADBEEF, "write/read word 0");

        // write then read back word 1
        write_word(32'h4, 32'd42);
        check_read(32'h4, 32'd42, "write/read word 1");

        // word-addressing check: word 2
        write_word(32'h8, 32'hCAFEF00D);
        check_read(32'h0, 32'hDEADBEEF, "word 0 unaffected by word 2 write");
        check_read(32'h4, 32'd42,       "word 1 unaffected by word 2 write");
        check_read(32'h8, 32'hCAFEF00D, "word 2 correctly written");

        // write-disabled check
        mem_write  = 1'b0;
        addr       = 32'h0;
        write_data = 32'hFFFFFFFF;
        @(posedge clk);
        #1;
        check_read(32'h0, 32'hDEADBEEF, "write disabled -> word 0 unchanged");

        if (errors == 0)
            $display("\n=== ALL TESTS PASSED ===");
        else
            $display("\n=== %0d TEST(S) FAILED ===", errors);

        $stop;
    end

endmodule