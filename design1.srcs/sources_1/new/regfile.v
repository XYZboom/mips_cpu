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
    output reg [31:0] reg_read_out2
    );
    reg [31:0] registers[31:0];
    integer i;
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
    end
endmodule








