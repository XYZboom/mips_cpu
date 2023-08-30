`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2023/08/27 13:56:05
// Design Name: 
// Module Name: main_sim
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


module main_sim();
    wire clk;
    wire reset;
    clk_sim clk_sim(
        .clk   (clk),
        .reset (reset)
    );
    main main(
        .clk    (clk),
        .reset  (reset)
    );
endmodule
