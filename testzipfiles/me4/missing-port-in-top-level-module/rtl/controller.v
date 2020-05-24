`timescale 1ns/1ps
`define WORD_WIDTH  32
`define MEM_ADDR_WIDTH 32

`define INST_BEQ_OPCODE     6'h04
`define INST_BNE_OPCODE     6'h05
`define INST_LW_OPCODE      6'h23
`define INST_SW_OPCODE      6'h2B
`define INST_RTYPE_OPCODE   6'h00
`define INST_ADDI_OPCODE    6'h08
`define INST_ADDIU_OPCODE   6'h09
`define INST_ANDI_OPCODE    6'h0C
`define INST_ORI_OPCODE     6'h0D
`define INST_SLTI_OPCODE    6'h0A 
`define INST_JUMP_OPCODE    6'h02
`define INST_JAL_OPCODE     6'h03

`define INST_RTYPE_ADD_FUNCT    6'h20
`define INST_RTYPE_SUB_FUNCT    6'h22
`define INST_RTYPE_AND_FUNCT    6'h24
`define INST_RTYPE_OR_FUNCT     6'h25
`define INST_RTYPE_XOR_FUNCT    6'h26
`define INST_RTYPE_SLL_FUNCT    6'h00
`define INST_RTYPE_SRL_FUNCT    6'h02
`define INST_RTYPE_SLT_FUNCT    6'h2A
`define INST_RTYPE_JR_FUNCT     6'h08

`define ALUSEL_ADD      4'b0001
`define ALUSEL_SUB      4'b0011
`define ALUSEL_AND      4'b0111
`define ALUSEL_OR       4'b1111
`define ALUSEL_SLT      4'b1110
`define ALUSEL_SLL      4'b1100
`define ALUSEL_SRL      4'b1000
`define ALUSEL_DEFAULT  4'h0

module controller (
    input clk,
    input nrst,
    input [`WORD_WIDTH - 1:0] inst,     // from instruction memory
    input alu_zero,                     // from ALU
    output reg reg_write,
    output reg reg_dst,
    output reg alu_src,
    output reg mem_to_reg,
    output reg pc_src,
    output reg jump,
    output reg jal,
    output reg jr,
    output reg sll,
    output reg srl,
    output reg [3:0] alusel
);

    wire [5:0] inst_opcode;
    wire [4:0] inst_rs;
    wire [4:0] inst_rt;
    wire [4:0] inst_rd;
    wire [4:0] inst_shamt;
    wire [5:0] inst_funct;
    wire [15:0] inst_imm;

    assign inst_opcode = inst[31:26];
    assign inst_rs = inst[25:21];
    assign inst_rt = inst[20:16];
    assign inst_rd = inst[15:11];
    assign inst_shamt = inst[10:6];
    assign inst_funct = inst[5:0];
    assign inst_imm = inst[15:0];

    // alusel control signal
    always @ (*) begin
        case (inst_opcode)
            `INST_LW_OPCODE,
            `INST_SW_OPCODE,
            `INST_ADDI_OPCODE:
                alusel <= `ALUSEL_ADD;

            `INST_BEQ_OPCODE,
            `INST_BNE_OPCODE:
                alusel <= `ALUSEL_SUB;  

            `INST_RTYPE_OPCODE:
                case (inst_funct)
                    `INST_RTYPE_ADD_FUNCT: alusel <= `ALUSEL_ADD;
                    `INST_RTYPE_SUB_FUNCT: alusel <= `ALUSEL_SUB;
                    `INST_RTYPE_AND_FUNCT: alusel <= `ALUSEL_AND;
                    `INST_RTYPE_OR_FUNCT:  alusel <= `ALUSEL_OR;
                    `INST_RTYPE_SLT_FUNCT: alusel <= `ALUSEL_SLT;
                    `INST_RTYPE_SLL_FUNCT: alusel <= `ALUSEL_SLL;
                    `INST_RTYPE_SRL_FUNCT: alusel <= `ALUSEL_SRL;
                    default: alusel <= `ALUSEL_DEFAULT;
                endcase

            `INST_SLTI_OPCODE: alusel <= `ALUSEL_SLT;
            `INST_ANDI_OPCODE: alusel <= `ALUSEL_AND;
            `INST_ORI_OPCODE:  alusel <= `ALUSEL_OR;

            default:           alusel <= `ALUSEL_DEFAULT;
        endcase
    end

    // alu_src control signal
    always @ (*) begin
        case (inst_opcode)
            `INST_LW_OPCODE,
            `INST_SW_OPCODE,
            `INST_ADDI_OPCODE,
            `INST_ANDI_OPCODE,
            `INST_SLTI_OPCODE,
            `INST_ORI_OPCODE:
                alu_src <= 1'b1;
            default:
                alu_src <= 1'b0;
        endcase
    end

    // reg_dst control signal
    always @ (*) begin
        case (inst_opcode)
            `INST_RTYPE_OPCODE:  reg_dst <= 1'b1;
            default:             reg_dst <= 1'b0;
        endcase
    end

    // reg_write control signal
    always @ (*) begin
        case (inst_opcode)
            `INST_RTYPE_OPCODE,
            `INST_ADDI_OPCODE,
            `INST_ANDI_OPCODE,
            `INST_SLTI_OPCODE,
            `INST_ORI_OPCODE,
            `INST_LW_OPCODE,
            `INST_JAL_OPCODE:
                reg_write <= 1'b1;
            default:
                reg_write <= 1'b0;
        endcase
    end

    // data_wr & mem_to_reg control signals
    always @ (*) begin
        case (inst_opcode)
            `INST_LW_OPCODE: {mem_to_reg} <= 1'b1;
            `INST_SW_OPCODE: {mem_to_reg} <= 1'b0;
            default:         {mem_to_reg} <= 1'b0;
        endcase
    end

    // pc_src control signal
    always @ (*) begin
        case (inst_opcode)
            `INST_BEQ_OPCODE: pc_src <= alu_zero ? 1'b1 : 1'b0;
            `INST_BNE_OPCODE: pc_src <= !alu_zero ? 1'b1 : 1'b0;
            default: pc_src <= 0;
        endcase
    end

    // jump control signal
    always @ (*) begin
        case (inst_opcode)
            `INST_JUMP_OPCODE,
            `INST_JAL_OPCODE:
                jump <= 1'b1;
            default:
                jump <= 1'b0;
        endcase
    end

    // jal, jr control signals
    always @ (*) begin
        case (inst_opcode)
            `INST_JAL_OPCODE: 
                {jal, jr} <= 2'b10;

            `INST_RTYPE_OPCODE:
                case (inst_funct)
                    `INST_RTYPE_JR_FUNCT:   {jal, jr} <= 2'b01;
                    default:                {jal, jr} <= 2'b00;
                endcase

            default:
                {jal, jr} <= 2'b00;
        endcase
    end

    // sll, srl control signals
    always @ (*) begin
        case (inst_opcode)
            `INST_RTYPE_OPCODE:
                case (inst_funct)
                    `INST_RTYPE_SLL_FUNCT: {sll, srl} <= 2'b10;
                    `INST_RTYPE_SRL_FUNCT: {sll, srl} <= 2'b01;
                    default:               {sll, srl} <= 2'b00;
                endcase
            default: {sll, srl} <= 2'b0;
        endcase
    end

endmodule