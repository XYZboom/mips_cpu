`timescale 1ns / 1ps

module alu(
    input [11:0] alu_ctrl,
    input [31:0] alu_src1,
    input [31:0] alu_src2,
    output reg[31:0] alu_result
    );
    always @(*) begin
        casez (alu_ctrl)
            12'b000000100000: alu_result = alu_src1 + alu_src2; // add
            12'b001000??????: alu_result = alu_src1 + alu_src2; // addi
            12'b000000100010: alu_result = alu_src1 - alu_src2; // sub
             // logic
            12'b000000100100: alu_result = alu_src1 & alu_src2; // and
            12'b001100??????: alu_result = alu_src1 & alu_src2; // andi
            12'b000000100101: alu_result = alu_src1 | alu_src2; // or
            12'b001101??????: alu_result = alu_src1 | alu_src2; // ori
            12'b000000100110: alu_result = alu_src1 ^ alu_src2; // xor
            12'b001110??????: alu_result = alu_src1 ^ alu_src2; // xori
            12'b000000100111: alu_result = ~(alu_src1 | alu_src2); // nor
            12'b000000000?00: alu_result = alu_src2 << alu_src1; // sll  sllv
            12'b000000000?10: alu_result = alu_src2 >> alu_src1; // srl  srlv
            12'b000000000?11: alu_result = $signed(alu_src2) >>> alu_src1; // sra  srav
            // compare
            12'b000000101010: alu_result = $signed(alu_src1) < $signed(alu_src2); // slt
            12'b000000101011: alu_result = alu_src1 < alu_src2; // sltu
            // lui
            12'b001111??????: alu_result = {alu_src2[15:0], 16'b0}; // lui
            default: alu_result = 32'b0;
        endcase
    end
endmodule