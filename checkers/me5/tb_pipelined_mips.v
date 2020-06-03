`timescale 1ns/1ps
`define ADDR_WIDTH  5
`define WORD_WIDTH  32
`define MEM_WIDTH   8
// `define MEM_DEPTH   4096
`define CLK_PERIOD  20
`define DEL_IN      `CLK_PERIOD*0.25
`define IVERILOG
`define test_all

module tb_pipelined_mips();
    reg clk;
    reg nrst;
    wire [`WORD_WIDTH-1:0] inst_addr;
    wire [`WORD_WIDTH-1:0] inst;
    wire [`WORD_WIDTH-1:0] data_addr;
    wire [`WORD_WIDTH-1:0] data_in;
    wire [`WORD_WIDTH-1:0] data_out;
    wire data_wr;
    wire [`WORD_WIDTH-1:0] pc_IF;
    wire [`WORD_WIDTH-1:0] pc_ID;
    wire [`WORD_WIDTH-1:0] pc_EXE;
    wire [`WORD_WIDTH-1:0] pc_MEM;
    wire [`WORD_WIDTH-1:0] pc_WB;

    parameter LW_SW = 34;
    parameter ADD   = 17;
    parameter SUB   = 17;
    parameter SLT   = 17;
    parameter ADDI  = 17;
    parameter SLTI  = 17;
    parameter SLL   = 96;
    parameter SRL   = 96;
    parameter BEQ   = 7;
    parameter BNE   = 7;
    parameter J     = 4;
    parameter JAL   = 7;
    parameter JR    = 4;

    parameter NOP_TIMEOUT = 20;     // number of NOP's for timeout
    parameter CC_TIMEOUT = 10000;   // number of clock cycles for timeout

    reg done;
    integer clk_no;
    integer nop;

    integer out_act, out_exp;

    integer inst_case [0:12];   // number of test cases per instruction
    integer inst_score [0:12];  // score per instruction
    integer inst_pos;           // current instruction
    integer addr_pos;           // current data address
    integer addr_end;           // end data address for current instruction

    `ifdef test_lw_sw
        parameter INST_NO = 1;
        initial begin
            inst_case[0]  = LW_SW;
        end
    `elsif test_arithmetic
        parameter INST_NO = 5;
        initial begin
            inst_case[0]  = ADD;
            inst_case[1]  = SUB;
            inst_case[2]  = SLT;
            inst_case[3]  = ADDI;
            inst_case[4]  = SLTI;
        end
    `elsif test_sll
        parameter INST_NO = 1;
        initial begin
            inst_case[0]  = SLL;
        end
    `elsif test_srl
        parameter INST_NO = 1;
        initial begin
            inst_case[0]  = SRL;
        end
    `elsif test_beq
        parameter INST_NO = 1;
        initial begin
            inst_case[0]  = BEQ;
        end
    `elsif test_bne
        parameter INST_NO = 1;
        initial begin
            inst_case[0]  = BNE;
        end
    `elsif test_jump
        parameter INST_NO = 3;
        initial begin
            inst_case[0]  = J;
            inst_case[1]  = JAL;
            inst_case[2]  = JR;
        end
    `else
        parameter INST_NO = 13;
        initial begin
            inst_case[0]  = LW_SW;
            inst_case[1]  = ADD;
            inst_case[2]  = SUB;
            inst_case[3]  = SLT;
            inst_case[4]  = ADDI;
            inst_case[5]  = SLTI;
            inst_case[6]  = SLL;
            inst_case[7]  = SRL;
            inst_case[8]  = BEQ;
            inst_case[9]  = BNE;
            inst_case[10] = J;
            inst_case[11] = JAL;
            inst_case[12] = JR;
        end
    `endif

    `ifdef SDF
        initial begin
            $sdf_annotate("../mapped/pipelined_mips_mapped.sdf", PIPELINED_MIPS);
        end
    `endif

    pipelined_mips PIPELINED_MIPS(
        .clk(clk),
        .nrst(nrst),
        .inst(inst),
        .inst_addr(inst_addr),
        .data_addr(data_addr),
        .data_in(data_in),
        .data_out(data_out),
        .data_wr(data_wr),
        .pc_IF(pc_IF),
        .pc_ID(pc_ID),
        .pc_EXE(pc_EXE),
        .pc_MEM(pc_MEM),
        .pc_WB(pc_WB)
    );

    datamem DATAMEM(
        .clk(clk),
        .data_addr(data_addr),
        .data_wr(data_wr),
        .data_in(data_out),
        .data_out(data_in)
    );

    instmem INSTMEM(
        .clk(clk),
        .inst_addr(inst_addr),
        .inst(inst)
    );

    outmem OUTMEM(
    );

    always begin
        #(`CLK_PERIOD/2) clk = ~clk;
    end
    
    always@(posedge clk) begin
        if (!nrst) 
            clk_no = 0;
        else
            clk_no = clk_no + 1;
    end

    always@(posedge clk) begin  
        if (!nrst) 
            nop = 0;
        else begin
            if (inst == 32'd0)
                nop = nop + 1;
            else
                nop = 0;
        end
    end

    initial begin
        `ifdef IVERILOG
            $dumpfile("tb_pipelined_mips.vcd");
            $dumpvars;
        `endif

        `ifdef VCS
            $vcdplusfile("tb_pipelined_mips.vpd");
            $vcdpluson;
        `endif
        
        clk = 1'b0;    
        nrst = 1'b0;
        #(`CLK_PERIOD*10);
        #(`CLK_PERIOD/2);
        #(`DEL_IN);

        nrst = 1'b1;
        done = 1'b0;
        while (done != 1'b1) begin
            #(`CLK_PERIOD);
            if ( (nop == NOP_TIMEOUT) || (clk_no >= CC_TIMEOUT) )
                done = 1'b1;
        end

        addr_pos = 0;
        addr_end = 0;
        for (inst_pos = 0; inst_pos < INST_NO; inst_pos = inst_pos + 1) begin
            addr_end = addr_end + inst_case[inst_pos];
            inst_score[inst_pos] = 0;

            while (addr_pos < addr_end) begin
                out_act = { DATAMEM.memory[(addr_pos*4)+0], 
                            DATAMEM.memory[(addr_pos*4)+1], 
                            DATAMEM.memory[(addr_pos*4)+2], 
                            DATAMEM.memory[(addr_pos*4)+3]};
                out_exp = { OUTMEM.memory[(addr_pos*4)+0], 
                            OUTMEM.memory[(addr_pos*4)+1],
                            OUTMEM.memory[(addr_pos*4)+2], 
                            OUTMEM.memory[(addr_pos*4)+3]};

                if (out_act == out_exp)
                    inst_score[inst_pos] = inst_score[inst_pos] + 1;
                else 
                    $display("%d %x %x", addr_pos, out_act, out_exp);

                addr_pos = addr_pos + 1;
            end
        end

        $display("");
        $display("Instruction        | Score | Total");
        $display("-------------------|-------|-------");

        `ifdef test_lw_sw
            $display("LW/SW              | %5d | %5d", inst_score[0], inst_case[0]);
        `elsif test_arithmetic
            $display("ADD                | %5d | %5d", inst_score[0], inst_case[0]);
            $display("SUB                | %5d | %5d", inst_score[1], inst_case[1]);
            $display("SLT                | %5d | %5d", inst_score[2], inst_case[2]);
            $display("ADDI               | %5d | %5d", inst_score[3], inst_case[3]);
            $display("SLTI               | %5d | %5d", inst_score[4], inst_case[4]);
        `elsif test_sll
            $display("SLL                | %5d | %5d", inst_score[0], inst_case[0]);
        `elsif test_srl
            $display("SRL                | %5d | %5d", inst_score[0], inst_case[0]);
        `elsif test_beq
            $display("BEQ                | %5d | %5d", inst_score[0], inst_case[0]);
        `elsif test_bne
            $display("BNE                | %5d | %5d", inst_score[0], inst_case[0]);  
        `elsif test_jump
            $display("J                  | %5d | %5d", inst_score[0], inst_case[0]);
            $display("JAL                | %5d | %5d", inst_score[1], inst_case[1]);
            $display("JR                 | %5d | %5d", inst_score[2], inst_case[2]);    
        `else 
            $display("LW/SW              | %5d | %5d", inst_score[0], inst_case[0]);
            $display("ADD                | %5d | %5d", inst_score[1], inst_case[1]);
            $display("SUB                | %5d | %5d", inst_score[2], inst_case[2]);
            $display("SLT                | %5d | %5d", inst_score[3], inst_case[3]);
            $display("ADDI               | %5d | %5d", inst_score[4], inst_case[4]);
            $display("SLTI               | %5d | %5d", inst_score[5], inst_case[5]);
            $display("SLL                | %5d | %5d", inst_score[6], inst_case[6]);
            $display("SRL                | %5d | %5d", inst_score[7], inst_case[7]);
            $display("BEQ                | %5d | %5d", inst_score[8], inst_case[8]);
            $display("BNE                | %5d | %5d", inst_score[9], inst_case[9]);
            $display("J                  | %5d | %5d", inst_score[10], inst_case[10]);
            $display("JAL                | %5d | %5d", inst_score[11], inst_case[11]);
            $display("JR                 | %5d | %5d", inst_score[12], inst_case[12]);
        `endif

        $display("");
        $display("Number of clock cycles: %d", clk_no);
        $display("");    
        $finish;
    end

endmodule