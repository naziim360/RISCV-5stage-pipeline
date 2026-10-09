// hazard_unit.sv -- Load-use hazard detection
module hazard_unit(
    input logic  id_ex_mem_read,
    input logic [4:0] id_ex_rd_addr,
    input logic [4:0] id_rs1_addr ,id_rs2_addr,
    input logic id_uses_rs1, id_uses_rs2,  

    output logic stall
      
);
    always_comb begin
        stall = id_ex_mem_read                                      // load instruction in id/ex
                && id_ex_rd_addr != 5'b0                           // rd is not r0
                && ( ((id_ex_rd_addr == id_rs1_addr ) && id_uses_rs1) || ((id_ex_rd_addr == id_rs2_addr) && id_uses_rs2));
                // one of the source registers in if/id is the same as rd in id/ex
    end
endmodule