`timescale 1ns / 1ps

module comparer(
    input [10:0] cmp_op,
    input [31:0] cmp_src1,
    input [31:0] cmp_src2,
    output reg cmp_out,
    output reg is_branch
    );
    always @(*) begin
        is_branch = 1;
        casez (cmp_op) 
            11'b000100?????: cmp_out <= cmp_src1 == cmp_src2;
            11'b000101?????: cmp_out <= cmp_src1 != cmp_src2;
            11'b00000100001: cmp_out <= cmp_src1 >= 0;
            11'b00011100000: cmp_out <= cmp_src1 > 0;
            11'b00011000000: cmp_out <= cmp_src1 <= 0;
            11'b00000100000: cmp_out <= cmp_src1 < 0;
            default begin
                cmp_out <= 0;
                is_branch <= 0;
            end
        endcase
    end
endmodule
