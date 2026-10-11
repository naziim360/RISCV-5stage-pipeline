// riscv single cycle top level module datapath 
module datapath
import alu_pkg::*;
(
    input logic clk,
    input logic reset
);

    // Instruction fields
    logic [31:0] instruction;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    // Register File
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] rd_data;
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    
    // Program Counter
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;
    logic [31:0] pc_target;

    // branch_resolve
    logic branch_taken;
    
    // ALU
    logic [31:0] alu_input_a, alu_input_b;
    logic [31:0] alu_result;

    // memory
    logic [31:0] mem_read_data;
    
    // Control Signals
    logic        reg_write;
    logic        mem_read;
    logic        mem_write;
    logic        branch;
    logic        jump;
    logic [1:0]  alu_src_a;
    logic        alu_src_b;
    alu_op_t     alu_op;
    logic [1:0]  result_src;
    
    // Sign-extended immediate
    logic [31:0] imm_ext;   
    
    branch_resolve u_branch_resolve(
        .funct3       (funct3),
        .rs1          (rs1_data),
        .rs2          (rs2_data),
        .branch_taken (branch_taken)
    );

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];

    assign pc_plus_4 = pc + 32'd4;
    assign pc_target = {alu_result[31:1], 1'b0};
    assign pc_next = ((branch && branch_taken) || jump) ? pc_target : pc_plus_4;

    always_ff @(posedge clk or posedge reset) begin
        if(reset)
            pc <= 32'b0;
        else
            pc <= pc_next;

    end

    // instruction fetch
    I_mem u_i_mem(
        .addr  (pc),
        .instr (instruction)
    );



    control_unit u_control_unit(
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        .reg_write (reg_write),
        .mem_read (mem_read),
        .mem_write (mem_write),
        .branch (branch),
        .jump (jump),
        .jalr (), // unused for now
        .alu_src_a (alu_src_a),
        .alu_src_b (alu_src_b),
        .alu_op (alu_op),
        .result_src (result_src)
    );  


    imm_gen u_imm_gen(
        .instruction (instruction),
        .imm_out (imm_ext)
    ); 

    regfile u_register_file(
        .clk (clk),
        .we (reg_write),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rd_addr  (rd_addr),
        .rd_data  (rd_data),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );



    assign alu_input_b = (alu_src_b) ? imm_ext : rs2_data;

    always_comb begin
        case(alu_src_a)
            2'b00: alu_input_a = rs1_data;
            2'b01: alu_input_a = pc;
            2'b10: alu_input_a = 32'b0;
            default: alu_input_a = rs1_data; // should not happen
        endcase
    end

    alu u_alu(
        .alu_a (alu_input_a),
        .alu_b (alu_input_b),
        .alu_op (alu_op),
        .alu_result (alu_result),
        .alu_flag_zero () // unused for now
    );
    

    D_mem u_d_mem(  
        .clk (clk),
        .mem_read (mem_read),
        .mem_write (mem_write),
        .addr (alu_result),
        .write_data (rs2_data),
        .read_data (mem_read_data)
    );

    always_comb begin
        case (result_src)
            2'b00: rd_data = alu_result;
            2'b01: rd_data = mem_read_data;
            2'b10: rd_data = pc_plus_4;
            default: rd_data = alu_result; // should not happen
        endcase
    end
    



endmodule 