// D_mem.sv -- Data Memory (behavioral, simulation-only)

module D_mem #(
    parameter int    DEPTH_WORDS = 256,
    parameter bit    PRELOAD     = 1'b0,
    parameter string INIT_FILE   = "../asm/dmem_test.mem"
) (
    input  logic        clk,
    input  logic        mem_read, // unused for now
    input  logic        mem_write,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    logic [31:0] mem [0:DEPTH_WORDS-1];

    initial begin
        if (PRELOAD) begin
            $readmemh(INIT_FILE, mem);
        end
    end

    // asynchronous read, word-addressed
    assign read_data = mem[addr[31:2]];

    // synchronous write
    always_ff @(posedge clk) begin
        if (mem_write) begin
            mem[addr[31:2]] <= write_data;
        end
    end

endmodule