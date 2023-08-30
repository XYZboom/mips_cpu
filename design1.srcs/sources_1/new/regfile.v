`timescale 1ns / 1ps

module regfile(
    input  clk,
    input  reset,
    input  [4:0]  reg_read_addr1,
    input  [4:0]  reg_read_addr2,
    input  [4:0]  reg_write_addr,
    input         reg_write_enable,
    input  [31:0] reg_write_value,
    output reg [31:0] reg_read_out1,
    output reg [31:0] reg_read_out2,
    // 额外的用于保存读取返回地址的字段
    input  [31:0] ra_write_value,
    input  [4:0]  ra_write_addr,
    input         ra_write_enable,
    input  [4:0]  ra_read_addr,
    output [31:0] ra_read_out
    );
    reg [31:0] registers[31:0];
    integer i;
    assign ra_read_out = registers[ra_read_addr];
    always @(reset) begin
        for (i = 0; i < 32; i = i + 1) begin
            registers[i] <= 0;
        end
    end
    // 不在此处下降沿读，因为if段需要提前生成转移条件
    always @(*) begin
        reg_read_out1 <= registers[reg_read_addr1];
        reg_read_out2 <= registers[reg_read_addr2];
    end
    // 时钟上升沿写
    always @(posedge clk) begin
        // 0号寄存器内永远为0
        if (reg_write_enable && reg_write_addr != 0) begin
            registers[reg_write_addr] <= reg_write_value;
        end
        // 保存返回地址
        if (ra_write_enable) begin
            registers[ra_write_addr] <= ra_write_value;
        end
    end
endmodule








