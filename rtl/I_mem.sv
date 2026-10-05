module I_mem #(
    parameter int    DEPTH_WORDS = 16,
	parameter IMEM_INIT_FILE = "../asm/prog.mem"
) (
    input  logic [31:0] addr,   
    output logic [31:0] instr
);

    logic [31:0] mem [0:DEPTH_WORDS-1];

    initial begin
        $readmemh(IMEM_INIT_FILE, mem);
    end

    assign instr = mem[addr[31:2]];

endmodule