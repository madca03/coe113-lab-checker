`timescale 1ns/1ps
`define WORD_WIDTH  32
`define MEM_ADDR_WIDTH 32

module datapath (
    input clk,
    input nrst,
    input reg_write,
    input reg_dst,
    input alu_src,
    input mem_to_reg,
    input pc_src,
    input jump,
    input jal,
    input jr,
    input sll,
    input srl,
    input [3:0] alusel,
    input [`WORD_WIDTH - 1:0] inst,                 // from instruction memory
    input [`WORD_WIDTH - 1:0] mem_data_in,          // from data memory to processor
    
    output alu_zero,                                // from ALU
    output reg [`MEM_ADDR_WIDTH - 1:0] inst_addr,   // program counter to instruction memory
    output [`MEM_ADDR_WIDTH - 1:0] data_addr,       // data memory address
    output [`WORD_WIDTH - 1:0] mem_data_out         // from processor to data memory
);

    // instruction decode
    wire [4:0] inst_rs;
    wire [4:0] inst_rt;
    wire [4:0] inst_rd;
    wire [4:0] inst_shamt;
    wire [15:0] inst_imm;
    wire [`WORD_WIDTH - 1:0] inst_imm_sign_extended;
    wire [15:0] inst_jump_target_addr;

    // register file ports
    wire [4:0] rd_addrA;
    wire [4:0] rd_addrB;
    reg [4:0] wr_addr;
    reg [`WORD_WIDTH - 1:0] wr_data;
    wire [`WORD_WIDTH - 1:0] rd_dataA;
    wire [`WORD_WIDTH - 1:0] rd_dataB;

    // ALU ports
    wire [`WORD_WIDTH - 1:0] opA;
    wire [`WORD_WIDTH - 1:0] opB;
    wire [`WORD_WIDTH - 1:0] alu_res;

    // Program counter next and plus 4
    reg [`WORD_WIDTH - 1:0] next_inst_addr;
    wire [`WORD_WIDTH - 1:0] inst_addr_plus_4;

    // instruction decode
    assign inst_rs = inst[25:21];
    assign inst_rt = inst[20:16];
    assign inst_rd = inst[15:11];
    assign inst_shamt = inst[10:6];
    assign inst_imm = inst[15:0];
    assign inst_imm_sign_extended = {{16{inst[15]}}, inst[15:0]};
    assign inst_jump_target_addr = inst[25:0];

    // register file read addr ports
    assign rd_addrA = inst_rs;
    assign rd_addrB = inst_rt;

    // register file wr_addr port
    always @ (*) begin
        case (jal)
            1'b1: wr_addr <= 32'd31;                        // for jal instructions
            1'b0: wr_addr <= reg_dst ? inst_rd : inst_rt;   // for other instructions
        endcase
    end

    // register file wr_data port
    always @ (*) begin
        case (jal)
            1'b1: wr_data <= inst_addr_plus_4;
            1'b0: wr_data <= mem_to_reg ? mem_data_in : alu_res;
        endcase
    end

    rf U1 (.clk(clk),
        .nrst(nrst),
        .rd_addrA(rd_addrA),
        .rd_addrB(rd_addrB),
        .wr_addr(wr_addr),
        .wr_en(reg_write),
        .wr_data(wr_data),
        .rd_dataA(rd_dataA),
        .rd_dataB(rd_dataB)
    );

    // ALU ports
    assign opA = (sll || srl) ? { {27{1'b0}}, inst_shamt } : rd_dataA;
    assign opB = alu_src ? inst_imm_sign_extended : rd_dataB;

    alu U2 (.opA(opA), 
        .opB(opB),
        .alusel(alusel),
        .alu_res(alu_res),
        .alu_zero(alu_zero)
    );

    assign inst_addr_plus_4 = inst_addr + 4;

    // current instruction address (program counter)
    always @ (posedge clk or negedge nrst) begin
        if (!nrst) 
            inst_addr <= 0;
        else 
            inst_addr <= next_inst_addr;
    end

    // next instruction address
    always @ (*) begin
        case ({pc_src, jump, jr})
            3'b100: next_inst_addr <= {inst_imm_sign_extended[`WORD_WIDTH - 3:0], 2'b00} + inst_addr_plus_4;
            3'b010: next_inst_addr <= {inst_addr_plus_4[31:28], inst_jump_target_addr, 2'b00};
            3'b001: next_inst_addr <= rd_dataA;
            default: next_inst_addr <= inst_addr_plus_4;
        endcase
    end

    assign data_addr = alu_res;
    assign mem_data_out = rd_dataB;
endmodule