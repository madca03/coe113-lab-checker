`timescale 1ns/1ps
`include "defines.h"

module instmem(
    clk, 
    inst_addr, 
    inst
);

    input clk;
    input [`WORD_WIDTH-1:0] inst_addr;
    output [`WORD_WIDTH-1:0] inst;

    reg [`MEM_WIDTH-1:0] memory [0:`MEM_DEPTH-1];

    initial begin
        `ifdef test_lw_sw
            $readmemh("../asm/inst_parse/lw_sw.txt", memory);
        `elsif test_arithmetic
            $readmemh("../asm/inst_parse/arithmetic.txt", memory);
        `elsif test_sll
            $readmemh("../asm/inst_parse/sll.txt", memory);
        `elsif test_srl
            $readmemh("../asm/inst_parse/srl.txt", memory);
        `elsif test_beq
            $readmemh("../asm/inst_parse/beq.txt", memory);
        `elsif test_bne
            $readmemh("../asm/inst_parse/bne.txt", memory);
        `elsif test_jump
            $readmemh("../asm/inst_parse/jump.txt", memory);
        `else
            $readmemh("inst.txt", memory);
        `endif
    end

    // Read data port
    reg [`WORD_WIDTH-1:0] inst_temp;

    always@(posedge clk)
        inst_temp <= {memory[inst_addr],
                      memory[inst_addr+1],
                      memory[inst_addr+2],
                      memory[inst_addr+3]};

    assign #(`INPUT_DELAY) inst = inst_temp;

endmodule