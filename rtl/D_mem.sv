module D_mem #(
    parameter int    DEPTH_WORDS = 16,
    parameter bit    PRELOAD     = 1'b0,
	parameter DMEM_INIT_FILE = "../asm/prog.mem"
	 
) (
    input  logic        clk,
    input  logic        mem_read,
    input  logic        mem_write,
    input  logic [31:0] addr,
    input  logic [31:0] write_data,
    output logic [31:0] read_data
);

    logic [31:0] mem [0:DEPTH_WORDS-1];

    initial begin

        for (int i = 0; i < DEPTH_WORDS; i++) begin
            mem[i] = 32'b0;
        end

        if (PRELOAD) begin
            $readmemh(DMEM_INIT_FILE, mem);
        end
    end

    // asynchronous read
    assign read_data = mem_read ? mem[addr[31:2]] : 32'bx;

    // synchronous write
    always_ff @(posedge clk) begin
        if (mem_write) begin
            mem[addr[31:2]] <= write_data;
        end
    end

endmodule