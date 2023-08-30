`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/27 13:22:47
// Design Name: 
// Module Name: regfile_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module regfile_sim();
    wire clk;
    wire reset;
    clk_sim clk_sim(
        .clk   (clk),
        .reset (reset)
    );
    wire [31:0] rs_out;
    wire [31:0] rt_out;
    reg  [31:0] write;
    reg reg_write_enable;
    reg [4:0] rs;
    reg [4:0] rt;
    reg [4:0] rd;
    
    regfile regfile(
        .clk                (clk),
        .reset              (reset),
        .reg_read_addr1     (rs),
        .reg_read_addr2     (rt),
        .reg_write_addr     (rd),
        .reg_write_enable   (reg_write_enable),
        .reg_write_value    (write),
        .reg_read_out1      (rs_out),
        .reg_read_out2      (rt_out)
    );
    integer i;
    initial begin
        reg_write_enable = 1;
        #1;
        for (i=0;i<32;i=i+1) begin
            rs = i;
            rt = i + 1;
            rd = i + 1;
            write = i * 2;
            #2;
        end
    end
endmodule









