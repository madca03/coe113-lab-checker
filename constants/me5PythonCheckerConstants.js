"use strict";

module.exports = {
    STATUS: {
        SIMULATION_SUCCESS: 0,
        VVP_PROCESS_TIMEOUT: 1,
        IVERILOG_PROCESS_COMPILATION_ERROR: 2,
    },
    FILES_USED_FOR_CHECKING: [
        "data.txt",
        "inst.txt",
        "out.txt",
        "datamem.v",
        "instmem.v",
        "outmem.v",
        "tb_pipelined_mips.v",
        "run.py",
        "defines.h"
    ]
};
