`timescale 1ns/1ps

module controller(opcode, funct, sel_dest, wr_en, sel_opB, alu_op, sel_data, mem_wr, sel_pc);
  input [5:0] opcode;
  input [5:0] funct;
  output reg [1:0] sel_dest;
  output reg wr_en;
  output reg sel_opB;
  output reg [5:0] alu_op;
  output reg [1:0] sel_data;
  output reg mem_wr;
  output reg [1:0] sel_pc;

  parameter R_TYPE  = 6'b000_000;
  parameter ADD     = 6'b100_000;
  parameter SUB     = 6'b100_010;
  parameter SLT     = 6'b101_010;
  parameter SLL     = 6'b000_000;
  parameter SRL     = 6'b000_010;
  parameter JR      = 6'b001_000;

  parameter ADDI    = 6'b001_000;
  parameter SLTI    = 6'b001_010;
  parameter LW      = 6'b100_011;
  parameter SW      = 6'b101_011;
  parameter BEQ     = 6'b000_100;
  parameter BNE     = 6'b000_101;
  parameter J       = 6'b000_010;
  parameter JAL     = 6'b000_011;

  // sel_dest (0 if R-type; 1 if I-type; 2 if JAL)
  always@(*) begin
    case(opcode)
      R_TYPE: sel_dest = 2'b00;
      JAL: sel_dest = 2'b10;
      default: sel_dest = 2'b01;
    endcase
  end

  // wr_en (1 if R-type, I-type except SW)
  always@(*) begin
    case(opcode)
      R_TYPE, ADDI, SLTI, LW, JAL: wr_en = 1'b1;
      default: wr_en = 1'b0;
    endcase
  end

  // sel_opB (0 if R-type, BEQ, BNE) 
  always@(*) begin
    case(opcode)
      R_TYPE, BEQ, BNE: sel_opB = 1'b0;
      default: sel_opB = 1'b1;
    endcase
  end

  // alu_op 
  always@(*) begin
    case(opcode)
      R_TYPE: alu_op = funct;
      ADDI, LW, SW: alu_op = ADD;
      SLTI: alu_op = SLT;
      BEQ, BNE: alu_op = opcode;
      default: alu_op = 6'd0;
    endcase
  end

  // sel_data (1 if LW; 2 if JAL)
  always@(*) begin
    case(opcode)
      LW: sel_data = 2'b01;
      JAL: sel_data = 2'b10;
      default: sel_data = 2'b00;
    endcase
  end

  // mem_wr (1 if SW)
  always@(*) begin
    case(opcode)
      SW: mem_wr = 1'b1;
      default: mem_wr = 1'b0;
    endcase
  end

  // sel_pc (0 if pc+4; 1 if branch; 2 if jump; 3 if JR)
  always@(*) begin
    case(opcode)
      BEQ, BNE: sel_pc = 2'b01;
      J, JAL: sel_pc = 2'b10;
      R_TYPE:
        if (funct == JR) sel_pc = 2'b11;
        else sel_pc = 2'b00;
      default: sel_pc = 2'b00;
    endcase 
  end

endmodule
