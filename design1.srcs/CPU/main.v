`timescale 1ns / 1ps

module main(
    input clk,
    input reset
);
    wire reg_write_enable;
    wire [4:0]  reg_write_addr;
    wire [31:0] reg_write_value;
    wire pc_sel;
    wire is_branch;
    wire [31:0] imm_id;
    // jr 与 jalr 指令的返回地址需要额外的一个周期读出来
    wire is_jump_return;
    
    reg  [31:0] IR_if_id;
    reg  [31:0] IR_id_ex;
    wire [5:0] op_ex = IR_id_ex[31:26];
    wire r_type_ex = op_ex == 6'b0;
    wire [4:0] rd_ex = IR_id_ex[15:11];
    wire [4:0] rt_ex = IR_id_ex[20:16];
    wire jal_ex = IR_id_ex[31:26] == 6'b000011;
    wire jalr_ex = {IR_id_ex[31:26], IR_id_ex[20:16], IR_id_ex[10:0]} == 22'b1001;
    // 带链接的跳转
    wire j_link_type_ex = jal_ex || jalr_ex;
    wire [4:0] target_r_ex = j_link_type_ex ? 5'b11111 :
                             r_type_ex ? rd_ex : rt_ex;
    
    reg  [31:0] IR_ex_mem;
    wire [5:0] op_mem = IR_ex_mem[31:26];
    wire r_type_mem = op_mem == 6'b0;
    wire [4:0] rd_mem = IR_ex_mem[15:11];
    wire [4:0] rt_mem = IR_ex_mem[20:16];
    wire jal_mem = IR_ex_mem[31:26] == 6'b000011;
    wire jalr_mem = {IR_ex_mem[31:26], IR_ex_mem[20:16], IR_ex_mem[10:0]} == 22'b1001;
    // 带链接的跳转
    wire j_link_type_mem = jal_mem || jalr_mem;
    wire [4:0] target_r_mem = j_link_type_mem ? 5'b11111 : 
                            r_type_mem ? rd_mem : rt_mem;
    
    reg  [31:0] IR_mem_wb;
    wire [5:0] op_wb = IR_mem_wb[31:26];
    wire r_type_wb = op_wb == 6'b0;
    wire [4:0] rd_wb = IR_ex_mem[15:11];
    
    // ------------------ IF ---------------------------
    reg  [31:0] pc;
    reg  [31:0] new_pc;
    wire [31:0] inst_rom_read;
    wire [5:0] op_if = inst_rom_read[31:26];
    wire j_type_if = op_if[5:1] == 5'b00001;
    wire [31:0] j_type_addr_if = {pc[31:28], inst_rom_read[25:0], 2'b00};
    wire [4:0]  rs_if = inst_rom_read[25:21];
    wire [4:0]  rd_if = inst_rom_read[15:11];
    reg  [31:0] return_address_if_id;
    reg  [31:0] delay_return_address_if_id;
    wire [31:0] ra_read_out;
    always @(negedge clk) begin
        new_pc <= j_type_if ? j_type_addr_if :
            (is_jump_return) ? ra_read_out :
            (pc_sel && is_branch) ? new_pc + (imm_id << 2) : pc + 4;
        pc <= j_type_if ? j_type_addr_if :
            (is_jump_return) ? ra_read_out :
            (pc_sel && is_branch) ? new_pc + (imm_id << 2) : pc + 4;
    end
    always @(posedge clk) begin
        IR_if_id <= inst_rom_read;
        return_address_if_id <= pc + 4;
        delay_return_address_if_id <= return_address_if_id;
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
    wire jalr_id = {IR_if_id[31:26], IR_if_id[20:16], IR_if_id[10:0]} == 22'b1001;
    wire jr_id = {IR_if_id[31:26], IR_if_id[20:0]} == 27'b1000;
    wire jal_id = IR_if_id[31:26] == 6'b000011;
    // 带链接的跳转
    wire j_link_type_id = jal_id || jalr_id;
    
    assign is_jump_return = jalr_id || jr_id;
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
        .reg_read_out2      (rt_out_id)
    );
    
    comparer comparer(
        .cmp_op     (cmp_op),
        .cmp_src1   (rs_out_id),
        .cmp_src2   (rt_out_id),
        .cmp_out    (pc_sel),
        .is_branch  (is_branch)
    );
    
    // 重定向需要的内容，因此在这里声明
    reg  [31:0] alu_res_ex_mem;
    wire [31:0] alu_result;
    
    assign ra_read_out = // 如果mem段的写入目标是当前的rs，则重定向
            (rs_id == target_r_mem && target_r_mem != 5'b0) ? alu_res_ex_mem : 
            (rs_id == target_r_ex && target_r_ex != 5'b0) ? alu_result : rs_out_id
            ;
    always @(posedge clk) begin
        imm_id_ex <= imm_id;
        // 如果是链接，则存入返回地址
        A_id_ex <= j_link_type_id ? delay_return_address_if_id : 
            // 如果mem段的写入目标是当前的rs，则重定向
            (rs_id == target_r_mem && target_r_mem != 5'b0) ? alu_res_ex_mem : 
            (rs_id == target_r_ex && target_r_ex != 5'b0) ? alu_result : rs_out_id
            ;
        B_id_ex <= (rt_id == target_r_mem && target_r_mem != 5'b0) ? alu_res_ex_mem : 
            (rt_id == target_r_ex && target_r_ex != 5'b0) ? alu_result : rt_out_id
            ;
        IR_id_ex <= IR_if_id;
    end
    
    // ****************** ID ****************************
    // ------------------ EX ----------------------------
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
    reg  [31:0] B_ex_mem;
    
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
    
    data_ram data_ram(
        .clka       (clk),
        .addra      (data_ram_read_addr),
        .dina       (data_ram_write_value),
        .douta      (data_ram_read_value),
        .wea        (save_mem)
    );
    
    // 此处下降沿读，与上升沿写配合，避免ID与MEM的写后读冲突
    always @(negedge clk) begin
        lmd_mem_wb <= data_ram_read_value;
        alu_res_mem_wb <= alu_res_ex_mem;
        IR_mem_wb <= IR_ex_mem;
    end
    
    // ****************** MEM ****************************
    // ------------------ WB ---------------------------
    wire load_wb = IR_mem_wb[31:26] == 6'b100011;
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
    wire jal_wb = IR_mem_wb[31:26] == 6'b000011;
    wire jalr_wb = {IR_mem_wb[31:26], IR_mem_wb[20:16], IR_mem_wb[10:0]} == 22'b1001;
    // 带链接的跳转
    wire j_link_type_wb = jal_wb || jalr_wb;
    assign reg_write_enable = load_wb || r_type_wb || i_type_wb || j_link_type_wb;
    assign reg_write_value = load_wb ? lmd_mem_wb : alu_res_mem_wb;
    // jal 与 jalr 的写入地址是ra寄存器，即31号寄存器
    assign reg_write_addr = j_link_type_wb ? 5'b11111 :
                            r_type_wb ? rd_wb : rt_wb;
    // ****************** WB ****************************
    // ------------------ reset ---------------------------
    always @(reset) begin
        IR_if_id <= 0;
        IR_id_ex <= 0;
        IR_ex_mem <= 0;
        IR_mem_wb <= 0;
        pc <= 0;
        new_pc <= 0;
    end
    // ****************** reset ****************************
endmodule
