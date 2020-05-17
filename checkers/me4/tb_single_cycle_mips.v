`timescale 1ns/1ps
// `define PRINT_MEMORY
// `define VCS
// `define SDF
`define IVERILOG

`define DEL_IN  7*14
`define WORD_WIDTH  32
`define MEM_ADDR_WIDTH 32
`define CLK_PERIOD  50
`define MEM_DEPTH  2048
`define MEM_WIDTH  8
`define WORD_WIDTH 32

`define LW_SW_TEST_LEN  32
`define ADD_TEST_LEN    9
`define SUB_TEST_LEN    9
`define SLT_TEST_LEN    11
`define ADDI_TEST_LEN   9
`define SLTI_TEST_LEN   8
`define BEQ_TEST_LEN    10
`define BNE_TEST_LEN    10
`define J_TEST_LEN      4
`define JAL_TEST_LEN    4
`define RA_TEST_LEN     4
`define JR_TEST_LEN     3
`define SLL_TEST_LEN    64
`define SRL_TEST_LEN    64

`define TEST_LEN	`LW_SW_TEST_LEN + `ADD_TEST_LEN + `SUB_TEST_LEN + `SLT_TEST_LEN + `ADDI_TEST_LEN + `SLTI_TEST_LEN + `BEQ_TEST_LEN + `BNE_TEST_LEN + `J_TEST_LEN + `JAL_TEST_LEN + `RA_TEST_LEN + `JR_TEST_LEN + `SLL_TEST_LEN + `SRL_TEST_LEN

`define LW_SW_TEST_STOP `LW_SW_TEST_LEN
`define ADD_TEST_STOP   `LW_SW_TEST_STOP + `ADD_TEST_LEN
`define SUB_TEST_STOP   `ADD_TEST_STOP + `SUB_TEST_LEN
`define SLT_TEST_STOP   `SUB_TEST_STOP + `SLT_TEST_LEN
`define ADDI_TEST_STOP  `SLT_TEST_STOP + `ADDI_TEST_LEN
`define SLTI_TEST_STOP  `ADDI_TEST_STOP + `SLTI_TEST_LEN
`define BEQ_TEST_STOP   `SLTI_TEST_STOP + `BEQ_TEST_LEN
`define BNE_TEST_STOP   `BEQ_TEST_STOP + `BNE_TEST_LEN
`define J_TEST_STOP     `BNE_TEST_STOP + `J_TEST_LEN
`define JAL_TEST_STOP   `J_TEST_STOP + `JAL_TEST_LEN
`define RA_TEST_STOP    `JAL_TEST_STOP + `RA_TEST_LEN
`define JR_TEST_STOP    `RA_TEST_STOP + `JR_TEST_LEN
`define SLL_TEST_STOP   `JR_TEST_STOP + `SLL_TEST_LEN
`define SRL_TEST_STOP   `SLL_TEST_STOP + `SRL_TEST_LEN

`define MAX_STR_LEN_INST_RES    5

module tb_single_cycle_mips();
    
    task displayResult;
        input [`MAX_STR_LEN_INST_RES*8:0] instruction, test_len, test_passed;

        if (test_len == test_passed) begin
            $display("%s PASSED %d/%d", instruction, test_passed, test_len);
        end else begin
            $display("%s FAILED %d/%d", instruction, test_passed, test_len);
        end
    endtask

    reg clk;
    reg nrst;
    wire [`WORD_WIDTH - 1:0] inst;                  // 32-bit instruction (from instruction memory)
    wire [`WORD_WIDTH - 1:0] proc_data_in;          // data from memory to processor
    wire [`WORD_WIDTH - 1:0] proc_data_out;         // data from processor to memory
    wire [`MEM_ADDR_WIDTH - 1:0] inst_addr;         // program counter
    wire [`MEM_ADDR_WIDTH - 1:0] data_addr;         // data memory address
    wire data_wr;                                   // write data signal of data memory

    wire [5:0] inst_opcode;
    wire [5:0] inst_funct;

    assign inst_opcode = inst[31:26];
    assign inst_funct = inst[5:0];

    single_cycle_mips UUT (.clk(clk),
        .nrst(nrst),
        .inst(inst),
        .data_in(proc_data_in),
        .data_out(proc_data_out),
        .data_wr(data_wr),
        .inst_addr(inst_addr),
        .data_addr(data_addr)
    );

    instmem I1 (.inst_addr(inst_addr),
        .inst(inst)
    );

    datamem D1 (.clk(clk),
        .data_addr(data_addr),
        .data_wr(data_wr),
        .data_in(proc_data_out),
        .data_out(proc_data_in)
    );

    datamem_ans D2 ();

    always 
        #(`CLK_PERIOD / 2) clk = ~clk;

    integer i = 0;
    
    integer lw_sw_test_pass = 0;
    integer add_test_pass = 0;
    integer sub_test_pass = 0;
    integer slt_test_pass = 0;
    integer addi_test_pass = 0;
    integer slti_test_pass = 0;
    integer beq_test_pass = 0;
    integer bne_test_pass = 0;
    integer j_test_pass = 0;
    integer jal_test_pass = 0;
    integer ra_test_pass = 0;
    integer jr_test_pass = 0;
    integer sll_test_pass = 0;
    integer srl_test_pass = 0;
    
    integer has_error = 0;
    reg done; 

    reg [`WORD_WIDTH - 1:0] datamem_out;
    reg [`WORD_WIDTH - 1:0] datamem_out_ans;

    initial begin
        `ifdef IVERILOG
            $dumpfile("tb_single_cycle_mips.vcd");
            $dumpvars;
        `endif

        `ifdef VCS
            $vcdplusfile("tb_single_cycle_mips.vpd");
            $vcdpluson;
        `endif

        `ifdef SDF
            $sdf_annotate("../mapped/single_cycle_mips_mapped.sdf", UUT);    
        `endif

        clk = 0;
        nrst = 0;
        done = 0;
        #(`DEL_IN) nrst = 1;
    end

    always @ (posedge clk) begin
        if (inst == 32'd0)
            i = i + 1;
        else 
            i = 0;
        if (i == 10) 
            done = 1;
    end

    always @ (posedge done) begin
        `ifdef PRINT_MEMORY
            $display("Printing the final contents of the data memory:");
            $display("data # \t\taddress \tdata \t\tcorrect data");
            $display("-------- \t-------- \t-------- \t--------");
        `endif


        for (i = 0; i < `TEST_LEN; i = i + 1) begin
            datamem_out = {D1.memory[(i*4)], 
                            D1.memory[(i*4)+1],
                            D1.memory[(i*4)+2],
                            D1.memory[(i*4)+3]};
            
            datamem_out_ans = {D2.memory[(i*4)], 
                                D2.memory[(i*4)+1],
                                D2.memory[(i*4)+2],
                                D2.memory[(i*4)+3]};
            
            if (i < `LW_SW_TEST_STOP) begin
                if (datamem_out == datamem_out_ans) begin
                    lw_sw_test_pass = lw_sw_test_pass + 1;
                end
                else begin
                    $display("LW/SW FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `LW_SW_TEST_STOP) && (i < `ADD_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    add_test_pass = add_test_pass + 1;
                end
                else begin
                    $display("ADD FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `ADD_TEST_STOP) && (i < `SUB_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    sub_test_pass = sub_test_pass + 1;
                end
                else begin
                    $display("SUB FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `SUB_TEST_STOP) && (i < `SLT_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    slt_test_pass = slt_test_pass + 1;
                end
                else begin
                    $display("SLT FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `SLT_TEST_STOP) && (i < `ADDI_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    addi_test_pass = addi_test_pass + 1;
                end
                else begin
                    $display("ADDI FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `ADDI_TEST_STOP) && (i < `SLTI_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    slti_test_pass = slti_test_pass + 1;
                end
                else begin
                    $display("SLTI FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `SLTI_TEST_STOP) && (i < `BEQ_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    beq_test_pass = beq_test_pass + 1;
                end
                else begin
                    $display("BEQ FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `BEQ_TEST_STOP) && (i < `BNE_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    bne_test_pass = bne_test_pass + 1;
                end
                else begin
                    $display("BNE FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `BNE_TEST_STOP) && (i < `J_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    j_test_pass = j_test_pass + 1;
                end
                else begin
                    $display("J FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `J_TEST_STOP) && (i < `JAL_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    jal_test_pass = jal_test_pass + 1;
                end
                else begin
                    $display("JAL FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `JAL_TEST_STOP) && (i < `RA_TEST_STOP)) begin
                if (datamem_out == (datamem_out_ans - 32'h3000)) begin
                    ra_test_pass = ra_test_pass + 1;
                end
                else begin
                    $display("$RA FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `RA_TEST_STOP) && (i < `JR_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    jr_test_pass = jr_test_pass + 1;
                end
                else begin
                    $display("JR FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `JR_TEST_STOP) && (i < `SLL_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    sll_test_pass = sll_test_pass + 1;
                end
                else begin
                    $display("SLL FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            else if ((i >= `SLL_TEST_STOP) && (i < `SRL_TEST_STOP)) begin
                if (datamem_out == datamem_out_ans) begin
                    srl_test_pass = srl_test_pass + 1;
                end
                else begin
                    $display("SRL FAILED - (data memory addr: %X)", i*4);
                    has_error = 1;
                end
            end

            `ifdef PRINT_MEMORY
                $display("%8d \t%X \t%X \t%X",
                    i,
                    i*4,
                    datamem_out,
                    datamem_out_ans
                )        
            `endif
        end

        // LW / SW TEST
        displayResult("LW/SW", `LW_SW_TEST_LEN, lw_sw_test_pass);
        // ARITHMETIC TEST
        displayResult("ADD", `ADD_TEST_LEN, add_test_pass);
        displayResult("SUB", `SUB_TEST_LEN, sub_test_pass);
        displayResult("SLT", `SLT_TEST_LEN, slt_test_pass);
        displayResult("ADDI", `ADDI_TEST_LEN, addi_test_pass);
        displayResult("SLTI", `SLTI_TEST_LEN, slti_test_pass);
        // BRANCH TEST
        displayResult("BEQ", `BEQ_TEST_LEN, beq_test_pass);
        displayResult("BNE", `BNE_TEST_LEN, bne_test_pass);
        // JUMP TEST
        displayResult("J", `J_TEST_LEN, j_test_pass);
        displayResult("JAL", `JAL_TEST_LEN, jal_test_pass);
        displayResult("RA", `RA_TEST_LEN, ra_test_pass);
        displayResult("JR", `JR_TEST_LEN, jr_test_pass);
        // SHIFT TEST
        displayResult("SLL", `SLL_TEST_LEN, sll_test_pass);
        displayResult("SRL", `SRL_TEST_LEN, srl_test_pass);

        $finish;
    end
endmodule
    
module datamem_ans();
    reg [`MEM_WIDTH-1:0] memory [0:`MEM_DEPTH-1];

    initial begin
        $readmemh("datamem_ans_parse.txt",memory);
    end
endmodule
