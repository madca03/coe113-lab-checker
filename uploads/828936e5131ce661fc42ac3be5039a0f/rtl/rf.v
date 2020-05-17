`timescale 1ns/1ps
`define ADDR_WIDTH  5
`define WORD_WIDTH  32
`define REGFILE_DEPTH 32

module rf(
    input clk,
    input nrst,
    input [`ADDR_WIDTH - 1:0] rd_addrA,
    input [`ADDR_WIDTH - 1:0] rd_addrB,
    input [`ADDR_WIDTH - 1:0] wr_addr,
    input wr_en,
    input [`WORD_WIDTH - 1:0] wr_data,
    
    output [`WORD_WIDTH - 1:0] rd_dataA,
    output [`WORD_WIDTH - 1:0] rd_dataB
);

    reg [`WORD_WIDTH - 1:0] regf [0:`REGFILE_DEPTH - 1];

    wire [`WORD_WIDTH - 1:0] reg0 ;
    wire [`WORD_WIDTH - 1:0] reg1 ;
    wire [`WORD_WIDTH - 1:0] reg2 ;
    wire [`WORD_WIDTH - 1:0] reg3 ;
    wire [`WORD_WIDTH - 1:0] reg4 ;
    wire [`WORD_WIDTH - 1:0] reg5 ;
    wire [`WORD_WIDTH - 1:0] reg6 ;
    wire [`WORD_WIDTH - 1:0] reg7 ;
    wire [`WORD_WIDTH - 1:0] reg8 ;
    wire [`WORD_WIDTH - 1:0] reg9 ;
    wire [`WORD_WIDTH - 1:0] reg10 ;
    wire [`WORD_WIDTH - 1:0] reg11 ;
    wire [`WORD_WIDTH - 1:0] reg12 ;
    wire [`WORD_WIDTH - 1:0] reg13 ;
    wire [`WORD_WIDTH - 1:0] reg14 ;
    wire [`WORD_WIDTH - 1:0] reg15 ;
    wire [`WORD_WIDTH - 1:0] reg16 ;
    wire [`WORD_WIDTH - 1:0] reg17 ;
    wire [`WORD_WIDTH - 1:0] reg18 ;
    wire [`WORD_WIDTH - 1:0] reg19 ;
    wire [`WORD_WIDTH - 1:0] reg20 ;
    wire [`WORD_WIDTH - 1:0] reg21 ;
    wire [`WORD_WIDTH - 1:0] reg22 ;
    wire [`WORD_WIDTH - 1:0] reg23 ;
    wire [`WORD_WIDTH - 1:0] reg24 ;
    wire [`WORD_WIDTH - 1:0] reg25 ;
    wire [`WORD_WIDTH - 1:0] reg26 ;
    wire [`WORD_WIDTH - 1:0] reg27 ;
    wire [`WORD_WIDTH - 1:0] reg28 ;
    wire [`WORD_WIDTH - 1:0] reg29 ;
    wire [`WORD_WIDTH - 1:0] reg30 ;
    wire [`WORD_WIDTH - 1:0] reg31 ;

    assign reg0 = regf[0];
    assign reg1 = regf[1];
    assign reg2 = regf[2];
    assign reg3 = regf[3];
    assign reg4 = regf[4];
    assign reg5 = regf[5];
    assign reg6 = regf[6];
    assign reg7 = regf[7];
    assign reg8 = regf[8];
    assign reg9 = regf[9];
    assign reg10 = regf[10];
    assign reg11 = regf[11];
    assign reg12 = regf[12];
    assign reg13 = regf[13];
    assign reg14 = regf[14];
    assign reg15 = regf[15];
    assign reg16 = regf[16];
    assign reg17 = regf[17];
    assign reg18 = regf[18];
    assign reg19 = regf[19];
    assign reg20 = regf[20];
    assign reg21 = regf[21];
    assign reg22 = regf[22];
    assign reg23 = regf[23];
    assign reg24 = regf[24];
    assign reg25 = regf[25];
    assign reg26 = regf[26];
    assign reg27 = regf[27];
    assign reg28 = regf[28];
    assign reg29 = regf[29];
    assign reg30 = regf[30];
    assign reg31 = regf[31];

    always @ (posedge clk or negedge nrst) begin
        if (!nrst) begin
            regf[0] <= 32'd0;
            regf[1] <= 32'd0;
            regf[2] <= 32'd0;
            regf[3] <= 32'd0;
            regf[4] <= 32'd0;
            regf[5] <= 32'd0;
            regf[6] <= 32'd0;
            regf[7] <= 32'd0;
            regf[8] <= 32'd0;
            regf[9] <= 32'd0;
            regf[10] <= 32'd0;
            regf[11] <= 32'd0;
            regf[12] <= 32'd0;
            regf[13] <= 32'd0;
            regf[14] <= 32'd0;
            regf[15] <= 32'd0;
            regf[16] <= 32'd0;
            regf[17] <= 32'd0;
            regf[18] <= 32'd0;
            regf[19] <= 32'd0;
            regf[20] <= 32'd0;
            regf[21] <= 32'd0;
            regf[22] <= 32'd0;
            regf[23] <= 32'd0;
            regf[24] <= 32'd0;
            regf[25] <= 32'd0;
            regf[26] <= 32'd0;
            regf[27] <= 32'd0;
            regf[28] <= 32'd0;
            regf[29] <= 32'd0;
            regf[30] <= 32'd0;
            regf[31] <= 32'd0;
        end
        else begin
            if (wr_en && wr_addr)
               regf[wr_addr] <= wr_data;
        end
    end

    assign rd_dataA = regf[rd_addrA];
    assign rd_dataB = regf[rd_addrB];

endmodule