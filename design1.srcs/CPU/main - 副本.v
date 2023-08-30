`timescale 1ns / 1ps

module main(
    input clk,
    input reset
);
    wire reg_write_enable;
    wire [5:0]  reg_write_addr;
    wire [31:0] reg_write_value;
    wire pc_sel;
    wire is_branch;
    wire [31:0] imm_id;
    
    // ------------------ IF ---------------------------
    reg  [31:0] pc;
    reg  [31:0] new_pc;
    wire [31:0] inst_rom_read;
    reg  [31:0] IR_if_id;
    wire [5:0] op_if = inst_rom_read[31:26];
    wire j_type_if = op_if[5:1] == 5'b00001;
    wire jal_if = j_type_if && op_if[0];
    wire jalr_if = {op_if, inst_rom_read[20:16], inst_rom_read[10:0]} == 22'b1001;
    wire [31:0] j_type_addr_if = {pc[31:28], inst_rom_read[25:0], 2'b00};
    wire jr_if = {inst_rom_read[31:26], inst_rom_read[20:0]} == 27'b1000;
    // jal jalr
    wire ra_write_enable = jal_if || jalr_if;
    wire [31:0] ra_write_value = pc + 4;
    wire [4:0]  rs_if = inst_rom_read[25:21];
    wire [4:0]  rd_if = inst_rom_read[15:11];
    wire [4:0]  ra_write_addr = 
        jal_if ? 5'd31 :
        jalr_if ? rd_if : rs_if
        ;
    wire [4:0]  ra_read_addr = rs_if;
    wire [31:0] ra_read_out;
    always @(posedge clk) begin
        new_pc <= j_type_if ? j_type_addr_if :
            (jr_if || jalr_if) ? ra_read_out :
            (pc_sel && is_branch) ? new_pc + (imm_id << 2) : pc + 4;
        pc <= j_type_if ? j_type_addr_if :
            (jr_if || jalr_if) ? ra_read_out :
            (pc_sel && is_branch) ? new_pc + (imm_id << 2) : pc + 4;
        IR_if_id <= inst_rom_read;
    end
    
    rom_1024x32b instruction_rom(
        .addra      (pc),
        .clka       (clk),
        .douta      (inst_rom_read)
    );
    // ****************** IF ****************************
    // ------------------ ID ---------------------------
    wire [31:0] rs_out_id;
    wire [31:0] rt_out_id;
    wire [4:0]  rs_id = IR_if_id[25:21];
    wire [4:0]  rt_id = IR_if_id[20:16];
    wire [4:0]  rd_id = IR_if_id[15:11];
    wire [10:0] cmp_op = {IR_if_id[31:26], IR_if_id[20:16]};
    reg  [31:0] A_id_ex;
    reg  [31:0] B_id_ex;
    reg  [31:0] imm_id_ex;
    reg  [31:0] IR_id_ex;
    
    // 符号位扩展
    assign imm_id = IR_if_id[15] ? {16'hffff, IR_if_id[15:0]} : {16'h0000, IR_if_id[15:0]};
    
    regfile regfile(
        .clk                (clk),
        .reset              (reset),
        .reg_read_addr1     (rs_id),
        .reg_read_addr2     (rt_id),
        .reg_write_addr     (reg_write_addr),
        .reg_write_enable   (reg_write_enable),
        .reg_write_value    (reg_write_value),
        .reg_read_out1      (rs_out_id),
        .reg_read_out2      (rt_out_id),
        .ra_write_value     (ra_write_value),
        .ra_write_addr      (ra_write_addr),
        .ra_write_enable    (ra_write_enable),
        .ra_read_addr       (ra_read_addr),
        .ra_read_out        (ra_read_out)
    );
    
    comparer comparer(
        .cmp_op     (cmp_op),
        .cmp_src1   (rs_out_id),
        .cmp_src2   (rt_out_id),
        .cmp_out    (pc_sel),
        .is_branch  (is_branch)
    );
    
    always @(posedge clk) begin
        imm_id_ex <= imm_id;
        A_id_ex <= rs_out_id;
        B_id_ex <= rt_out_id;
        IR_id_ex <= IR_if_id;
    end
    
    // ****************** ID ****************************
    // ------------------ EX ----------------------------
    wire [5:0] op_ex = IR_id_ex[31:26];
    wire [5:0] func_ex = IR_id_ex[5:0];
    wire [5:0] sa_ex = IR_id_ex[10:6];
    // load指令操作码特征
    wire load_ex = IR_id_ex[31:29] == 3'b100;
    wire shift_type_ex = (
        func_ex == 6'b000000 ||
        func_ex == 6'b000010 ||
        func_ex == 6'b000011
        ) && op_ex == 6'b0;
    wire [31:0] alu_src1 = shift_type_ex ? sa_ex : A_id_ex;
    wire [31:0] alu_src2;
    wire [11:0] alu_ctrl = {op_ex, func_ex};
    wire [31:0] alu_result;
    reg  [31:0] alu_res_ex_mem;
    reg  [31:0] B_ex_mem;
    reg  [31:0] IR_ex_mem;
    
    assign alu_src2 = 
        op_ex != 0 ? imm_id_ex : // 立即数寻址
            B_id_ex;
    
    alu alu(
        .alu_ctrl   (alu_ctrl),
        .alu_src1   (alu_src1),
        .alu_src2   (alu_src2),
        .alu_result (alu_result)
    );
    
    always @(posedge clk) begin
        alu_res_ex_mem <= alu_result;
        B_ex_mem <= B_id_ex;
        IR_ex_mem <= IR_id_ex;
    end
    // ****************** EX ****************************
    // ------------------ MEM ----------------------------
    // load指令操作码特征
    wire load_mem = IR_ex_mem[31:29] == 3'b100;
    // save指令操作码特征
    wire save_mem = IR_ex_mem[31:29] == 3'b101;
    wire [31:0] data_ram_read_addr = alu_res_ex_mem;
    wire [31:0] data_ram_read_value;
    wire [31:0] data_ram_write_value = B_ex_mem;
    reg  [31:0] lmd_mem_wb;
    reg  [31:0] alu_res_mem_wb;
    reg  [31:0] IR_mem_wb;
    
    data_ram data_ram(
        .clka       (clk),
        .addra      (data_ram_read_addr),
        .dina       (data_ram_write_value),
        .douta      (data_ram_read_value),
        .wea        (save_mem)
    );
    
    always @(negedge clk) begin
        lmd_mem_wb <= data_ram_read_value;
        alu_res_mem_wb <= alu_res_ex_mem;
        IR_mem_wb <= IR_ex_mem;
    end
    
    // ****************** MEM ****************************
    // ------------------ WB ---------------------------
    wire [5:0] op_wb = IR_mem_wb[31:26];
    wire load_wb = IR_mem_wb[31:29] == 3'b100;
    // R型指令操作码特征
    wire r_type_wb = op_wb == 6'b0;
    // I型指令操作码特征
    wire i_type_wb = 
        op_wb == 6'b001000 ||   // addi
        op_wb == 6'b001100 ||   // andi
        op_wb == 6'b001101 ||   // ori
        op_wb == 6'b001110 ||   // xori
        op_wb == 6'b100011 ||   // lw
        op_wb == 6'b001111    // lui
        ;
    wire [4:0]  rt_wb = IR_mem_wb[20:16];
    wire [4:0]  rd_wb = IR_mem_wb[15:11];
    assign reg_write_enable = load_wb || r_type_wb || i_type_wb;
    assign reg_write_value = load_wb ? lmd_mem_wb : alu_res_mem_wb;
    assign reg_write_addr = r_type_wb ? rd_wb : rt_wb;
    // ****************** WB ****************************
    // ------------------ reset ---------------------------
    always @(reset) begin
        IR_if_id <= 0;
        pc <= 0;
        new_pc <= 0;
    end
    // ****************** reset ****************************
endmodule
