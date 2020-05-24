`timescale 1ns/1ps
`define ADDR_WIDTH  5
`define WORD_WIDTH  32
`define REG_DEPTH   32

module rf(clk, nrst, rd_addrA, rd_addrB, wr_addr, wr_en, wr_data, rd_dataA, rd_dataB);
  input clk;
  input nrst;
  input [`ADDR_WIDTH-1:0] rd_addrA, rd_addrB;
  input [`ADDR_WIDTH-1:0] wr_addr;
  input wr_en;
  input [`WORD_WIDTH-1:0] wr_data;
  output reg [`WORD_WIDTH-1:0] rd_dataA, rd_dataB;

  reg [`WORD_WIDTH-1:0] register [0:`REG_DEPTH-1];
  integer i;

  always@(posedge clk or negedge nrst)
    if (!nrst) begin
      for (i = 0; i < `REG_DEPTH; i = i + 1)
        register[i] <= 32'd0;
    end
    else begin
      if ( (wr_en) && (wr_addr) )
        register[wr_addr] <= wr_data;
    end

  always@(*) begin
    rd_dataA = register[rd_addrA];
    rd_dataB = register[rd_addrB];
  end
endmodule
