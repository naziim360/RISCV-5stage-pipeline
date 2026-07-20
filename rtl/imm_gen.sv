//RV32I Immediate Generator

package riscv_opcodes_pkg;

    //RV32I opcodes, (inst[6:0])
    typedef enum logic [6:0]
    {
        OPC_LOAD    = 7'b0000011,  // I-type: lw, lh, lb, lhu, lbu
        OPC_OP_IMM  = 7'b0010011,  // I-type: addi, andi, ori, xori, slti, sltiu, slli/srli/srai
        OPC_STORE   = 7'b0100011,  // S-type: sw, sh, sb
        OPC_OP      = 7'b0110011,  // R-type: add, sub, and, or, xor, sll, srl, sra, slt, sltu
        OPC_BRANCH  = 7'b1100011,  // B-type: beq, bne, blt, bge, bltu, bgeu
        OPC_JALR    = 7'b1100111,  // I-type: jalr
        OPC_JAL     = 7'b1101111,  // J-type: jal
        OPC_LUI     = 7'b0110111,  // U-type: lui
        OPC_AUIPC   = 7'b0010111   // U-type: auipc
    } opcode_t;
 
endpackage


module imm_gen
import riscv_opcodes_pkg::*;
(
    input  logic[31:0] instruction,
    output logic[31:0] imm_out
);
    
    opcode_t opcode ;
    assign opcode = opcode_t'(instruction[6:0]);
    
    always_comb begin
        case (opcode)
        // I-type: imm[11:0] lives in instr[31:20], sign-extend
            OPC_LOAD , OPC_OP_IMM , OPC_JALR   :  imm_out = {{20{instruction[31]}} , instruction[31:20]};

            // S-type: imm[11:5] in instr[31:25], imm[4:0] in instr[11:7],sign-extend
            OPC_STORE: imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
        
            // B-type: immediate encodes a branch offset, this exact bit order is per
            // the RISC-V spec:
            //   imm[12]   -> instr[31]
            //   imm[11]   -> instr[7]
            //   imm[10:5] -> instr[30:25]
            //   imm[4:1]  -> instr[11:8]
            //   imm[0]    -> always 0
            OPC_BRANCH: imm_out = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};

            // U-type: immediate occupies the top 20 bits directly,
            // bottom 12 bits are zero
            OPC_LUI, OPC_AUIPC : imm_out = {instruction[31:12] , 12'b0};

            // J-type: 
            //   imm[20]    -> instr[31]
            //   imm[19:12] -> instr[19:12]
            //   imm[11]    -> instr[20]
            //   imm[10:1]  -> instr[30:21]
            //   imm[0]     -> always 0
            OPC_JAL: imm_out = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

            default: imm_out = 32'b0;
        endcase 

    end

endmodule