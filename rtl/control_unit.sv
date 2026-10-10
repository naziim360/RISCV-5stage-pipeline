// control_unit.sv -- RV32I Control Unit
// Purely combinational. Decodes opcode/funct3/funct7 into every
// control signal the rest of the datapath needs.

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic       reg_write,
    output logic       mem_read,
    output logic       mem_write,
    output logic       branch,
    output logic       jump,
    output logic       jalr,
    output logic [1:0] alu_src_a,
    output logic       alu_src_b,
    output alu_pkg::alu_op_t alu_op,
    output logic [1:0] result_src,
    output logic       uses_rs1,
    output logic       uses_rs2
);

    import riscv_opcodes_pkg::*;
    import alu_pkg::*;

    // funct7 bit [5] to distinguish SUB from ADD, and SRA from SRL
    logic funct7_b5;
    assign funct7_b5 = funct7[5];

    always_comb begin

        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        jalr       = 1'b0;
        alu_src_a  = 2'b00;   // rs1
        alu_src_b  = 1'b0;    // rs2
        alu_op     = ALU_ADD;
        result_src = 2'b00;   // alu_result
        uses_rs1   = 1'b0;
        uses_rs2   = 1'b0;  

        case (opcode_t'(opcode))

            // R-type
            OPC_OP: begin
                reg_write  = 1'b1;
                alu_src_a  = 2'b00;  // rs1
                alu_src_b  = 1'b0;   // rs2
                result_src = 2'b00;  // alu_result
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;

                case (funct3)
                    3'b000:  if (funct7_b5) alu_op = ALU_SUB; else alu_op = ALU_ADD;
                    3'b001:  alu_op = ALU_SLL;
                    3'b010:  alu_op = ALU_SLT;
                    3'b011:  alu_op = ALU_SLTU;
                    3'b100:  alu_op = ALU_XOR;
                    3'b101:  if (funct7_b5) alu_op = ALU_SRA; else alu_op = ALU_SRL;
                    3'b110:  alu_op = ALU_OR;
                    3'b111:  alu_op = ALU_AND;
                    default: alu_op = ALU_ADD;
                endcase
            end

            // I-type ALU
            OPC_OP_IMM: begin
                reg_write  = 1'b1;
                alu_src_a  = 2'b00;  // rs1
                alu_src_b  = 1'b1;   // imm
                result_src = 2'b00;  // alu_result
                uses_rs1   = 1'b1;

                case (funct3)
                    3'b000:  alu_op = ALU_ADD;
                    3'b001:  alu_op = ALU_SLL;
                    3'b010:  alu_op = ALU_SLT;
                    3'b011:  alu_op = ALU_SLTU;
                    3'b100:  alu_op = ALU_XOR;
                    3'b101:  if (funct7_b5) alu_op = ALU_SRA; else alu_op = ALU_SRL;
                    3'b110:  alu_op = ALU_OR;
                    3'b111:  alu_op = ALU_AND;
                    default: alu_op = ALU_ADD;
                endcase
            end

            // Loads: lw 
            OPC_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src_a  = 2'b00;  // rs1
                alu_src_b  = 1'b1;   // imm  (address = rs1 + imm)
                alu_op     = ALU_ADD;
                result_src = 2'b01;  // mem data
                uses_rs1   = 1'b1;
            end

            // Stores: sw
            OPC_STORE: begin
                mem_write  = 1'b1;
                alu_src_a  = 2'b00;  // rs1
                alu_src_b  = 1'b1;   // imm  (address = rs1 + imm)
                alu_op     = ALU_ADD;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;
            end
            
            // branches: beq, bne, blt, bge, bltu, bgeu
            OPC_BRANCH: begin
                branch     = 1'b1;
                alu_src_a  = 2'b01;  // pc
                alu_src_b  = 1'b1;   // imm
                alu_op     = ALU_ADD;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;
            end

            // jal: unconditional jump, 
            // rd <- pc + 4 
            // pc = pc + imm
            OPC_JAL: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                alu_src_a  = 2'b01;  // pc
                alu_src_b  = 1'b1;   // imm   
                alu_op     = ALU_ADD;
                result_src = 2'b10;  // pc + 4
            end

            // jalr: 
            // rd <- pc + 4 
            // pc = rs1 + imm            
            OPC_JALR: begin
                reg_write  = 1'b1;
                jump       = 1'b1;
                jalr       = 1'b1;
                alu_src_a  = 2'b00;  // rs1
                alu_src_b  = 1'b1;   // imm   
                alu_op     = ALU_ADD;
                result_src = 2'b10;  // pc + 4
                uses_rs1   = 1'b1;
            end

            // lui: rd <- imm  (imm << 12 already done in imm_gen)
            OPC_LUI: begin
                reg_write  = 1'b1;
                alu_src_a  = 2'b10;  // zero
                alu_src_b  = 1'b1;   // imm
                alu_op     = ALU_ADD;
                result_src = 2'b00;  // alu_result
            end

            // auipc: rd <- pc + imm
            OPC_AUIPC: begin
                reg_write  = 1'b1;
                alu_src_a  = 2'b01;  // pc
                alu_src_b  = 1'b1;   // imm
                alu_op     = ALU_ADD;
                result_src = 2'b00;  // alu_result
            end

            // unrecognized opcode: behave as a NOP
            default: ;

        endcase
    end

endmodule