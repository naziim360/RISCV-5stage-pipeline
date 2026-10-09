// hazard_unit.sv -- Load-use hazard detection
module hazard_unit(
    input logic  ex_mem_load,
    input logic [4:0] ex_mem_rd,
    input logic [4:0] id_ex_rs1, id_ex_rs2,
    output logic stall
      
);
    always_comb begin
        stall = ex_mem_load                                    //load instruction in ex/mem
                && ex_mem_rd != 5'b0                           //rd is not r0
                && (ex_mem_rd == id_ex_rs1||ex_mem_rd == id_ex_rs2);   // one of the source register in id/ex is same as rd in ex/mem
    end
endmodule