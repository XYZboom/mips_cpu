`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/26 18:12:01
// Design Name: 
// Module Name: sim_main
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


module clk_sim(
    output reg clk,
    output reg reset
);
    initial begin
        clk = 0;
        reset = 1;
        #1;
        reset = 0;
    end
    always begin
        #1;
        clk = ~clk;
    end
endmodule






