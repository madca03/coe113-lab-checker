"use strict";

module.exports = {
  STATUS: {
    SIMULATION_SUCCESS: 0,
    VVP_PROCESS_TIMEOUT: 1,
    IVERILOG_PROCESS_COMPILATION_ERROR: 2,  
  },
  FILES_USED_FOR_CHECKING: [
    "datamem_ans_parse.txt",
    "datamem_parse.txt",
    "instmem_parse.txt",
    "datamem.v",
    "instmem.v",
    "tb_single_cycle_mips.v",
    "run.py"
  ]
};
