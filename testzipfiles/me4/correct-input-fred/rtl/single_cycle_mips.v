`timescale 1ns/1ps
`define ADDR_WIDTH  5
`define WORD_WIDTH  32

module single_cycle_mips(clk, nrst, inst_addr, inst, data_addr, data_in, data_out, data_wr);
  input clk;
  input nrst;
  output reg [`WORD_WIDTH-1:0] inst_addr;
  input [`WORD_WIDTH-1:0] inst;
  output reg [`WORD_WIDTH-1:0] data_addr;
  input [`WORD_WIDTH-1:0] data_in;        // from memory to processor
  output reg [`WORD_WIDTH-1:0] data_out;  // from processor to memory
  output reg data_wr;

  reg [`WORD_WIDTH-1:0] pc_next;
  reg [`WORD_WIDTH-1:0] branch_next;
  reg [`WORD_WIDTH-1:0] j_next;

  reg [5:0] opcode;
  reg [`ADDR_WIDTH-1:0] rs, rt, rd;
  reg [4:0] shamt;
  reg [5:0] funct;
  reg [15:0] imm;
  reg [25:0] addr;

  reg [`ADDR_WIDTH-1:0] rd_addrA, rd_addrB;
  wire [`WORD_WIDTH-1:0] rd_dataA, rd_dataB;
  wire wr_en; 
  reg [`ADDR_WIDTH-1:0] wr_addr;
  reg [`WORD_WIDTH-1:0] wr_data;
  reg [`WORD_WIDTH-1:0] sign_extend;

  reg [`WORD_WIDTH-1:0] opA, opB; 
  wire [`WORD_WIDTH-1:0] alu_res;
  
  wire [1:0] sel_dest;
  wire sel_opB;
  wire [5:0] alu_op;
  wire [1:0] sel_data;
  wire mem_wr;
  wire [1:0] sel_pc;

  rf RF_U1(.clk(clk),
    .nrst(nrst),
    .rd_addrA(rd_addrA),
    .rd_addrB(rd_addrB),
    .wr_addr(wr_addr),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .rd_dataA(rd_dataA),
    .rd_dataB(rd_dataB)
  );

  alu ALU_U1(.opA(opA),
    .opB(opB),
    .alu_op(alu_op),
    .shamt(shamt),
    .alu_res(alu_res)
  );
  
  controller CONTROLLER_U1(.opcode(opcode),
    .funct(funct),
    .sel_dest(sel_dest),
    .wr_en(wr_en),
    .sel_opB(sel_opB),
    .alu_op(alu_op),
    .sel_data(sel_data),
    .mem_wr(mem_wr),
    .sel_pc(sel_pc)
  );

  // IF
  always@(*) begin
    pc_next = inst_addr + 4;
    branch_next = pc_next + {sign_extend[29:0], 2'b00};
    j_next = {inst_addr[31:28], addr, 2'b00};
  end
  
  always@(posedge clk or negedge nrst) begin
    if (!nrst)
      inst_addr <= 32'd0;
    else
      case(sel_pc)
        2'b01: inst_addr <= (alu_res)? branch_next : pc_next;
        2'b10: inst_addr <= j_next;
        2'b11: inst_addr <= rd_dataA;
        default: inst_addr <= pc_next;
      endcase
  end

  // ID
  always@(*) begin
    opcode = inst[31:26];
    rs = inst[25:21];
    rt = inst[20:16];
    rd = inst[15:11];
    shamt = inst[10:6];
    funct = inst[5:0];
    imm = inst[15:0];
    addr = inst[25:0];
  end

  always@(*) begin
    rd_addrA = rs;
    rd_addrB = rt;
   
    sign_extend = {{16{imm[15]}}, imm};
  end

  always@(*) begin
    case(sel_dest)
      2'b00: wr_addr = rd;
      2'b10: wr_addr = 5'b11111;
      default: wr_addr = rt;
    endcase
  end

  // EXE
  always@(*) begin
    opA = rd_dataA;
    opB = (sel_opB)? sign_extend : rd_dataB;
  end

  // MEM
  always@(*) begin
    data_addr = alu_res;
    data_out = rd_dataB;
    data_wr = mem_wr;
  end

  // WB
  always@(*) begin
    case(sel_data)
      2'b01: wr_data = data_in;
      2'b10: wr_data = pc_next;
      default: wr_data = alu_res;
    endcase
  end

endmodule
