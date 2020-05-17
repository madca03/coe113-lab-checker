`timescale 1ns/1ps
`define WORD_WIDTH  32
`define MEM_ADDR_WIDTH 32

module single_cycle_mips(
    input clk,
    input nrst,
    input [`WORD_WIDTH - 1:0] inst,             // 32-bit instruction (from instruction memory)
    input [`WORD_WIDTH - 1:0] data_in,          // data from memory to processor

    output [`WORD_WIDTH - 1:0] data_out,        // data from processor to memory
    output mem_write,                           // data memory write enable
    output mem_read,                            // data memory read enable
    output [`MEM_ADDR_WIDTH - 1:0] inst_addr,   // program counter
    output [`MEM_ADDR_WIDTH - 1:0] data_addr    // data memory address
);

    wire reg_write;
    wire reg_dst;
    wire alu_src;
    wire mem_to_reg;
    wire pc_src;
    wire jump;
    wire jal;
    wire jr;
    wire sll;
    wire srl;
    wire [3:0] alusel;
    wire alu_zero;

    datapath U1 (.clk(clk),
        .nrst(nrst),
        .reg_write(reg_write),
        .reg_dst(reg_dst),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .pc_src(pc_src),
        .jump(jump),
        .jal(jal),
        .jr(jr),
        .sll(sll),
        .srl(srl),
        .alusel(alusel),
        .inst(inst),
        .mem_data_in(data_in),
        .alu_zero(alu_zero),
        .inst_addr(inst_addr),
        .data_addr(data_addr),
        .mem_data_out(data_out)
    );

    controller U2 (.clk(clk),
        .nrst(nrst),
        .inst(inst),
        .alu_zero(alu_zero),
        .reg_write(reg_write),
        .reg_dst(reg_dst),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .alu_src(alu_src),
        .mem_to_reg(mem_to_reg),
        .pc_src(pc_src),
        .jump(jump),
        .jal(jal),
        .jr(jr),
        .sll(sll),
        .srl(srl),
        .alusel(alusel)
    );

endmodule