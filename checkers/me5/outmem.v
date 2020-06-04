`timescale 1ns/1ps
`define MEM_DEPTH  4096
`define MEM_WIDTH  8
`define WORD_WIDTH 32

module outmem(
);

    reg [`MEM_WIDTH-1:0] memory [0:`MEM_DEPTH-1];

    initial begin
        `ifdef test_lw_sw
            $readmemh("../asm/out_parse/lw_sw.txt", memory);
        `elsif test_arithmetic
            $readmemh("../asm/out_parse/arithmetic.txt", memory);
        `elsif test_sll
            $readmemh("../asm/out_parse/sll.txt", memory);
        `elsif test_srl
            $readmemh("../asm/out_parse/srl.txt", memory);
        `elsif test_beq
            $readmemh("../asm/out_parse/beq.txt", memory);
        `elsif test_bne
            $readmemh("../asm/out_parse/bne.txt", memory);
        `elsif test_jump
            $readmemh("../asm/out_parse/jump.txt", memory);
        `else
            $readmemh("out.txt", memory);
        `endif
    end

endmodule
