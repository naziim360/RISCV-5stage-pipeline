module forwarding_unit  (
    input logic[4:0] id_ex_rs1_addr,
    input logic[4:0] id_ex_rs2_addr,

    input logic[4:0] ex_mem_rd_addr,
    input logic      ex_mem_reg_write,

    input logic[4:0] mem_wb_rd_addr,
    input logic      mem_wb_reg_write,

    output logic[1:0] forward_a,
    output logic[1:0] forward_b

);


always_comb begin
    // forward_a
	if (ex_mem_reg_write &&
        ex_mem_rd_addr != 5'b0 &&
        id_ex_rs1_addr == ex_mem_rd_addr)
        forward_a = 2'b01;                  // rs1 from mem stage

    else if (mem_wb_reg_write &&
        mem_wb_rd_addr != 5'b0 &&
        id_ex_rs1_addr == mem_wb_rd_addr)
        forward_a = 2'b10;                  // rs1 from wb stage
    else 
        forward_a = 2'b00;                  // rs1 from regfile

	// forward_b
	if (ex_mem_reg_write &&
        ex_mem_rd_addr != 5'b0 &&
        id_ex_rs2_addr == ex_mem_rd_addr)
        forward_b = 2'b01;                  // rs2 from mem stage
    else if (mem_wb_reg_write &&
        mem_wb_rd_addr != 5'b0 &&
        id_ex_rs2_addr == mem_wb_rd_addr)
        forward_b = 2'b10;                  // rs2 from wb stage
    else 
        forward_b = 2'b00;                  // rs2 from regfile
end

endmodule