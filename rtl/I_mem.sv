// I_mem.sv -- Instruction Memory (behavioral, simulation-only)

module I_mem #(
    parameter int    DEPTH_WORDS = 256,          
    parameter string INIT_FILE   = "../asm/tb_imem_test.mem"  
) (
    input  logic [31:0] addr,   
    output logic [31:0] instr
);

    logic [31:0] mem [0:DEPTH_WORDS-1];

    initial begin
        $readmemh(INIT_FILE, mem);
    end

    assign instr = mem[addr[31:2]];

endmodule