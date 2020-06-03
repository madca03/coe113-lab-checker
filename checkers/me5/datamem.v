`timescale 1ns/1ps
`include "defines.h"

module datamem(
    clk,
    data_addr,
    data_wr,
    data_in,    // output of processor
    data_out    // input to processor
);

    input clk, data_wr;
    input [`WORD_WIDTH-1:0] data_addr, data_in;
    output [`WORD_WIDTH-1:0] data_out;

    reg [`MEM_WIDTH-1:0] memory [0:`MEM_DEPTH-1];

    initial begin
        `ifdef test_lw_sw
            $readmemh("../asm/data_parse/lw_sw.txt", memory);
        `elsif test_arithmetic
            $readmemh("../asm/data_parse/arithmetic.txt", memory);
        `elsif test_sll
            $readmemh("../asm/data_parse/sll.txt", memory);
        `elsif test_srl
            $readmemh("../asm/data_parse/srl.txt", memory);
        `elsif test_beq
            $readmemh("../asm/data_parse/beq.txt", memory);
        `elsif test_bne
            $readmemh("../asm/data_parse/bne.txt", memory);
        `elsif test_jump
            $readmemh("../asm/data_parse/jump.txt", memory);
        `else
            $readmemh("data.txt", memory);
        `endif
    end

    // Read data port
    reg [`WORD_WIDTH-1:0] data_out_temp;

    always@(posedge clk)
        data_out_temp <= {memory[data_addr],
                          memory[data_addr+1],
                          memory[data_addr+2],
                          memory[data_addr+3]};

    assign #(`INPUT_DELAY) data_out = data_out_temp;

    // Write data port
    always@(posedge clk)
        if (data_wr) begin
            memory[data_addr] <= data_in[31:24];
            memory[data_addr+1] <= data_in[23:16];
            memory[data_addr+2] <= data_in[15:8];
            memory[data_addr+3] <= data_in[7:0];
        end
    
endmodule