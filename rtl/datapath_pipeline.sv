module datapath_pipeline 
(
    input logic clk,
    input logic reset,
    output logic debug_out
);

    import riscv_opcodes_pkg::*;
    import alu_pkg::*;
    import pipeline_pkg::*;
	 

    if_id_reg_t  if_id,  if_id_next;
    id_ex_reg_t  id_ex,  id_ex_next;
    ex_mem_reg_t ex_mem, ex_mem_next;
    mem_wb_reg_t mem_wb, mem_wb_next;
	 
// ******** INSTRUCTION FETCH ********

    logic [31:0] pc, pc_plus_4, pc_next;
    logic [31:0] if_instruction;
    logic [31:0] ex_redirect_target; // assigned in stage EX 
    logic        ex_redirect_valid; // assigned in stage EX 

    logic stall; // comming from hazard unit

    assign pc_plus_4 = pc + 32'd4;
    assign pc_next = ex_redirect_valid ? ex_redirect_target : pc_plus_4;

    always_ff @(posedge clk, posedge reset) begin
        if(reset)
            pc<= 32'b0;
        else if(!stall) 
            pc <= pc_next;
    end

    I_mem #(
        .DEPTH_WORDS (256),
        .IMEM_INIT_FILE("../asm/prog_pipeline.mem")   
    ) u_I_mem
    (
        .addr(pc),
        .instr(if_instruction)
    );

    //if_id pipeline register
    logic flush_id;

    assign flush_id = ex_redirect_valid;

    always_comb begin
        if_id_next.pc = pc;
        if_id_next.pc_plus4= pc_plus_4;
        if_id_next.instr = if_instruction;
        if_id_next.valid = 1'b1;
    end

    always_ff @(posedge clk, posedge reset) begin
        if(reset)
            if_id <= '0;
		  else if(flush_id)
				 if_id <= '0;
        else if(!stall)
            if_id <= if_id_next;
        // else keep current instruction (stall)

    end



// *********** INSTRUCTION DECODE *********

// (register access || control_unit || hazard_unit || imm_gen )

    logic [6:0] opcode;
    logic [4:0] rd_addr, rs1_addr, rs2_addr;
    logic [2:0] funct3;
    logic [6:0] funct7;

    assign opcode   = if_id.instr[6:0];
    assign rd_addr  = if_id.instr[11:7];
    assign funct3   = if_id.instr[14:12];
    assign rs1_addr = if_id.instr[19:15];
    assign rs2_addr = if_id.instr[24:20];
    assign funct7   = if_id.instr[31:25];

    logic        reg_write, mem_read, mem_write, branch, jump, jalr;
    logic        uses_rs1, uses_rs2;   // instruction reads rs1/rs2
    logic [1:0]  alu_src_a;
    logic        alu_src_b;
    alu_op_t     alu_op;
    logic [1:0]  result_src;

    //control unit
    control_unit u_control_unit (
        .opcode     (opcode),
        .funct3     (funct3),
        .funct7     (funct7),
        .reg_write  (reg_write),
        .mem_read   (mem_read),
        .mem_write  (mem_write),
        .branch     (branch),
        .jump       (jump),
        .jalr       (jalr),
        .alu_src_a  (alu_src_a),
        .alu_src_b  (alu_src_b),
        .alu_op     (alu_op),
        .result_src (result_src),
        .uses_rs1   (uses_rs1),
        .uses_rs2   (uses_rs2)
    );

    //register file
    logic [31:0] rs1_data, rs2_data;
    logic [31:0] wb_data;

    regfile u_register_file (
        .clk      (clk),

        // comming from wb stage
        .we       (mem_wb.reg_write), 
        .rd_addr  (mem_wb.rd_addr),  
        .rd_data  (wb_data),
        
        // comming from if/id
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    //immediate generation
    logic [31:0] imm_ext;

    imm_gen u_imm_gen (
        .instruction (if_id.instr),
        .imm_out     (imm_ext)
    );
    
    //hazard detection
    hazard_unit u_hazard_unit(
        .id_ex_mem_read(id_ex.mem_read),
        .id_ex_rd_addr(id_ex.rd_addr),
        .id_rs1_addr(rs1_addr),
        .id_rs2_addr(rs2_addr),
        .id_uses_rs1(uses_rs1),
        .id_uses_rs2(uses_rs2),
        .stall(stall)
    );
    
    // id_ex pipeline register
    logic flush_ex;
    assign flush_ex = ex_redirect_valid || stall;

    always_comb begin
        id_ex_next.pc         = if_id.pc;
        id_ex_next.pc_plus4   = if_id.pc_plus4;  
        id_ex_next.rs1_data   = rs1_data;
        id_ex_next.rs2_data   = rs2_data;
        id_ex_next.imm        = imm_ext;
        id_ex_next.rs1_addr   = rs1_addr;
        id_ex_next.rs2_addr   = rs2_addr;
        id_ex_next.rd_addr    = rd_addr;
        id_ex_next.funct3     = funct3;
        id_ex_next.reg_write  = reg_write;
        id_ex_next.mem_read   = mem_read;
        id_ex_next.mem_write  = mem_write;
        id_ex_next.branch     = branch;
        id_ex_next.jump       = jump;
        //id_ex_next.jalr       = jalr;
        id_ex_next.alu_src_a  = alu_src_a;
        id_ex_next.alu_src_b  = alu_src_b;
        id_ex_next.alu_op     = alu_op;
        id_ex_next.result_src = result_src;
        id_ex_next.valid      = if_id.valid; 
    end

    always_ff@(posedge clk, posedge reset) begin
        if (reset)
                id_ex <= '0;
			else if (flush_ex)
					 id_ex <= '0;
        else if (!stall)
            id_ex <= id_ex_next;
    end




//   *********** EXECUTE ***********

// fowarding unit => ( alu || branch resolve)


        // forwarding unit
        logic[1:0] forward_a, forward_b;
        forwarding_unit u_forwarding_unit (
            .id_ex_rs1_addr   (id_ex.rs1_addr),
            .id_ex_rs2_addr   (id_ex.rs2_addr),
            .ex_mem_rd_addr   (ex_mem.rd_addr),
            .ex_mem_reg_write (ex_mem.reg_write),
            .mem_wb_rd_addr   (mem_wb.rd_addr),
            .mem_wb_reg_write (mem_wb.reg_write),
            .forward_a        (forward_a),
            .forward_b        (forward_b)
        );

        logic [31:0] fowarded_rs1, fowarded_rs2;
        logic [31:0] ex_mem_foward_value;
        logic [31:0] mem_read_data;         // assigned in memory access stage 

        assign ex_mem_foward_value = ex_mem.mem_read ? mem_read_data : ex_mem.alu_result;       // if its a load result is at the data_out
                                                                                                // of Dmem else it is at the alu result 
 
        always_comb begin
            case (forward_a)
                2'b00: fowarded_rs1 = id_ex.rs1_data;
                2'b01: fowarded_rs1 = ex_mem_foward_value;
                2'b10: fowarded_rs1 = wb_data;
                default: fowarded_rs1 = id_ex.rs1_data;
            endcase
            case (forward_b)
                2'b00: fowarded_rs2 = id_ex.rs2_data;
                2'b01: fowarded_rs2 = ex_mem_foward_value;
                2'b10: fowarded_rs2 = wb_data;
                default: fowarded_rs2 = id_ex.rs2_data;
            endcase
        end

        // alu
        logic [31:0] alu_op_a, alu_op_b;

        always_comb begin
            case (id_ex.alu_src_a)
                2'b00: alu_op_a = fowarded_rs1;
                2'b01: alu_op_a = id_ex.pc;
                2'b10: alu_op_a = 32'd0;
                default: alu_op_a = fowarded_rs1;
            endcase
            case (id_ex.alu_src_b)
                1'b0: alu_op_b = fowarded_rs2;
                1'b1: alu_op_b = id_ex.imm;
                default: alu_op_b = fowarded_rs2;
            endcase
        end
        
        logic [31:0] alu_result;
        alu u_alu (
            .alu_a(alu_op_a),
            .alu_b(alu_op_b),
            .alu_op(id_ex.alu_op),
            .alu_result(alu_result),
            .alu_flag_zero()
            
        );

        //branch resolve
        logic branch_taken;

        branch_resolve u_branch_resolve (
            .funct3       (id_ex.funct3),
            .rs1          (fowarded_rs1),
            .rs2          (fowarded_rs2),
            .branch_taken (branch_taken)
        );

        assign ex_redirect_valid = id_ex.valid && (id_ex.jump || (id_ex.branch && branch_taken));
        assign ex_redirect_target = {alu_result[31:1], 1'b0}; 

        //ex/mem pipeline register

        always_comb begin
            ex_mem_next.pc_plus4   = id_ex.pc_plus4;
            ex_mem_next.alu_result = alu_result;
            ex_mem_next.rs2_data   = fowarded_rs2;   // for store instruction
            ex_mem_next.rd_addr    = id_ex.rd_addr;
            ex_mem_next.reg_write  = id_ex.reg_write;
            ex_mem_next.mem_read   = id_ex.mem_read;
            ex_mem_next.mem_write  = id_ex.mem_write;
            ex_mem_next.result_src = id_ex.result_src;
            ex_mem_next.valid      = id_ex.valid;
        end

        always_ff @(posedge clk or posedge reset) begin
            if (reset) ex_mem <= '0;
            else       ex_mem <= ex_mem_next;
        end



// *********** MEMORY ACCESS ***********

    D_mem #(
        .DEPTH_WORDS (256),
        .PRELOAD     (1'b0)
    ) u_d_mem (
        .clk        (clk),
        .mem_read   (ex_mem.mem_read),
        .mem_write  (ex_mem.mem_write),
        .addr       (ex_mem.alu_result),
        .write_data (ex_mem.rs2_data),
        .read_data  (mem_read_data)
    );

// MEM/WB pipeline register


    always_comb begin
        mem_wb_next.pc_plus4      = ex_mem.pc_plus4;
        mem_wb_next.alu_result    = ex_mem.alu_result;
        mem_wb_next.mem_read_data = mem_read_data;
        mem_wb_next.rd_addr       = ex_mem.rd_addr;
        mem_wb_next.reg_write     = ex_mem.reg_write;
        mem_wb_next.result_src    = ex_mem.result_src;
        mem_wb_next.valid         = ex_mem.valid;
    end

    always_ff @(posedge clk or posedge reset) begin
        if (reset) mem_wb <= '0;
        else       mem_wb <= mem_wb_next;
    end



// *********** WRITE BACK ***********

    always_comb begin
        case (mem_wb.result_src)
            2'b00:   wb_data = mem_wb.alu_result;
            2'b01:   wb_data = mem_wb.mem_read_data;
            2'b10:   wb_data = mem_wb.pc_plus4;
            default: wb_data = mem_wb.alu_result;
        endcase
    end

    assign debug_out = wb_data[3]; //for synthesis only 

endmodule
        