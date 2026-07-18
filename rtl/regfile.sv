module regfile (
    input logic clk,
    input logic we,             // write enable
    input logic[4:0] rs1_addr,  // first source register num
    input logic[4:0] rs2_addr,  // second source register num
    input logic[4:0] rd_addr,   // destination register num
    input logic[31:0] rd_data,  // destination register data

    output logic[31:0] rs1_data, // first source register data
    output logic[31:0] rs2_data  // second source register data
);


//  the 32 registers
logic[31:0] registers [0:31];


// asynchronious read with x0 always 0
assign rs1_data = (rs1_addr == 5'b0) ? 32'b0 : registers[rs1_addr];
assign rs2_data = (rs2_addr == 5'b0) ? 32'b0 : registers[rs2_addr];

// symchronious write 
always_ff @(posedge clk) begin
    if (we && (rd_addr != 5'b00)) begin
        registers[rd_addr] <= rd_data;
    end
end
    

endmodule 