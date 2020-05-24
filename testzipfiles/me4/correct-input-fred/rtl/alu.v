`timescale 1ns/1ps
`define WORD_WIDTH  32

module alu(opA, opB, alu_op, shamt, alu_res);  
  input [`WORD_WIDTH-1:0] opA, opB;
  input [5:0] alu_op;
  input [4:0] shamt;
  output reg [`WORD_WIDTH-1:0] alu_res;

  parameter ADD     = 6'b100_000;
  parameter SUB     = 6'b100_010;
  parameter SLT     = 6'b101_010;
  parameter SLL     = 6'b000_000;
  parameter SRL     = 6'b000_010;
  parameter JR      = 6'b001_000;

  parameter BEQ     = 6'b000_100;
  parameter BNE     = 6'b000_101;

  wire overflow;
  wire [`WORD_WIDTH-1:0] temp;

  assign {overflow, temp} = {opA[31], opA} - {opB[31], opB};

  always@(*) begin
    case(alu_op)
      ADD: alu_res = opA + opB;
      SUB: alu_res = opA - opB;
      SLT: alu_res = (overflow)? 32'd1 : 32'd0;
      SLL: alu_res = opB << shamt;
      SRL: alu_res = opB >> shamt;
      BEQ: alu_res = (!temp)? 32'd1 : 32'd0;
      BNE: alu_res = (temp)? 32'd1 : 32'd0;
      default: alu_res = 32'd0;
    endcase
  end

endmodule
