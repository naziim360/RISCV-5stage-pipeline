module branch_resolve(
    input logic [2:0] funct3,
    input logic [31:0] rs1,rs2,

    output logic branch_taken
);

    always_comb begin
        case (funct3)
            3'b000: branch_taken = (rs1 == rs2);
            3'b001: branch_taken = (rs1 != rs2);
            3'b100: branch_taken = ($signed(rs1) < $signed(rs2));
            3'b101: branch_taken = ($signed(rs1) >= $signed(rs2));
            3'b110: branch_taken = (rs1 < rs2);
            3'b111: branch_taken = (rs1 >= rs2);
            default: branch_taken = 1'b0;
        endcase
    end

endmodule