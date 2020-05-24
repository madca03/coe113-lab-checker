`timescale 1ns/1ps
`define WORD_WIDTH  32
`define MEM_ADDR_WIDTH 32

`define ALUSEL_ADD      4'b0001
`define ALUSEL_SUB      4'b0011
`define ALUSEL_AND      4'b0111
`define ALUSEL_OR       4'b1111
`define ALUSEL_SLT      4'b1110
`define ALUSEL_SLL      4'b1100
`define ALUSEL_SRL      4'b1000
`define ALUSEL_DEFAULT  4'h0

module alu (
    input [`WORD_WIDTH - 1:0] opA,
    input [`WORD_WIDTH - 1:0] opB,
    input [3:0] alusel,
    output alu_zero,
    output reg [`WORD_WIDTH - 1:0] alu_res
);

    wire sign_opA;
    wire sign_opB;
    wire [`WORD_WIDTH - 1:0] mag_opA;
    wire [`WORD_WIDTH - 1:0] mag_opB;

    assign sign_opA = opA[31];
    assign sign_opB = opB[31];
    assign mag_opA = sign_opA ? (~opA + 1) : opA;
    assign mag_opB = sign_opB ? (~opB + 1) : opB;

    always @ (*) begin
        case (alusel)
            `ALUSEL_AND: alu_res <= opA & opB;
            `ALUSEL_OR:  alu_res <= opA | opB;
            `ALUSEL_ADD: alu_res <= opA + opB;
            `ALUSEL_SUB: alu_res <= opA - opB;
            `ALUSEL_SLT: begin
                case ({sign_opA, sign_opB})
                    2'b01: alu_res <= 32'd0;
                    2'b10: alu_res <= 32'd1;
                    2'b00: alu_res <= mag_opA < mag_opB ? 32'd1 : 32'd0;
                    2'b11: alu_res <= mag_opA > mag_opB ? 32'd1 : 32'd0;
                endcase
            end
            `ALUSEL_SLL: alu_res <= opB << opA;     // opA contains shamt
            `ALUSEL_SRL: alu_res <= opB >> opA;     // opA contains shamt
            default:     alu_res <= 0;
        endcase
    end

    assign alu_zero = alu_res ? 1'b0 : 1'b1;
endmodule