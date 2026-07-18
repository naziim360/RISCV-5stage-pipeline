package alu_pkg;

	typedef enum logic[3:0]{
        	ALU_ADD  = 4'b0000,
        	ALU_SUB  = 4'b0001,
        	ALU_AND  = 4'b0010,
        	ALU_OR   = 4'b0011,
        	ALU_XOR  = 4'b0100,
        	ALU_SLL  = 4'b0101,   // shift left logical
        	ALU_SRL  = 4'b0110,   // shift right logical
        	ALU_SRA  = 4'b0111,   // shift right arithmetic
        	ALU_SLT  = 4'b1000,   // set less than signed
        	ALU_SLTU = 4'b1001    // set less than unsigned

	}alu_op_t;
endpackage

module alu
	import alu_pkg::*;
	(
	input logic[31:0] alu_a,
	input logic[31:0] alu_b,
	input alu_op_t alu_op,
	output logic[31:0] alu_result,
	output logic alu_flag_zero
	);

	logic[4:0] shift;
	assign shift = alu_b[4:0];

	always_comb begin

		case (alu_op)
        		ALU_ADD  : alu_result = alu_a + alu_b;
        		ALU_SUB  : alu_result = alu_a - alu_b;
        		ALU_AND  : alu_result = alu_a & alu_b;
        		ALU_OR   : alu_result = alu_a | alu_b;
        		ALU_XOR  : alu_result = alu_a ^ alu_b;
        		ALU_SLL  : alu_result = alu_a << shift;
        		ALU_SRL  : alu_result = alu_a >> shift;
        		ALU_SRA  : alu_result = $signed(alu_a) >>> shift;
				ALU_SLT  : alu_result = ($signed(alu_a) < $signed(alu_b)) ? 32'd1 : 32'd0;
        		ALU_SLTU : alu_result = (alu_a < alu_b) ? 32'd1 : 32'd0;
			default : alu_result = 32'd0;

		endcase
	end

	assign alu_flag_zero = (alu_result==32'd0);

endmodule




	