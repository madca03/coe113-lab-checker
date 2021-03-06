#!/usr/bin/python3
import subprocess
import argparse
import shlex
import os
import time
import sys


class EXIT_STATUS:
    SIMULATION_SUCCESS = 0
    VVP_PROCESS_TIMEOUT = 1
    IVERILOG_PROCESS_COMPILATION_ERROR = 2


class VVP_PROCESS:
    class STATUS:
        TIMEOUT = 400
        SUCCESS = 0

    TIMEOUT_SECONDS = 1  # allowable simulation time


class IVERILOG_PROCESS:
    class STATUS:
        SUCCESS = 0


GENERATED_SIMULATION_FILE = "simv"
PIPELINED_MIPS_TESTBENCH_INSTANCE_NAME = "UUT"
PIPELINED_MIPS_MODULE_NAME = "pipelined_mips"


def print_iverilog_compilation_errors(process_stderr):
    missing_ports = []
    other_error_lines = []

    with process_stderr as f:
        for line in f:
            line = line.decode().strip()

            if "not a port of {}".format(PIPELINED_MIPS_TESTBENCH_INSTANCE_NAME) in line:
                search_str = "``"
                index = line.find(search_str)
                port = line[index + len(search_str):]

                search_str = "''"
                index = port.find(search_str)
                port = port[:index]

                missing_ports.append(port)
            else:
                other_error_lines.append(line)

    if len(missing_ports):
        for port in missing_ports:
            print("Missing {0} port in {1}.v module".format(
                port, PIPELINED_MIPS_MODULE_NAME), file=sys.stderr)

    if len(other_error_lines):
        for line in other_error_lines:
            print(line, file=sys.stderr)


def print_vvp_results(process_stdout):
    with process_stdout as f:
        test = ["LW/SW", "ADD", "SUB", "SLT", "SLL", "SRL",
                "ADDI", "SLTI", "BEQ", "BNE", "J", "JAL", "JR"]
        start = 0
        end = 0
        for line in f:
            line = line.decode().strip()
            if "WARNING" in line or "VCD info" in line or "data memory" in line:
                continue

            if "Score" in line:           # start
                start = 1
                end = 0
            if "clock cycles" in line:    # end
                end = 1
                start = 0

            if start == 1:
                line_nospace = line.replace(' ', '')
                line_split = line_nospace.split('|')

                if line_split[0] in test:
                    if line_split[-1] == line_split[-2]:
                        stat = "PASSED"
                    else:
                        stat = "FAILED"

                    line = "{} {} {}/{}".format(line_split[0], stat, line_split[1], line_split[2])
                else:
                    continue
            else:
                continue

            print(line)


def execute_iverilog(args=None):
    verilog_files = [f for f in os.listdir('.') if os.path.isfile(f) and f.endswith('.v')]
    verilog_files = ' '.join(verilog_files)

    iverilog_command = "iverilog -o {0} {1}".format(GENERATED_SIMULATION_FILE, verilog_files)
    if (args.show_iverilog_command):
        print("IVerilog command: {}".format(iverilog_command))
    iverilog_command = shlex.split(iverilog_command)

    iverilog_process = subprocess.Popen(
        iverilog_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    iverilog_process_status = iverilog_process.wait()

    return {
        'process': iverilog_process,
        'status': iverilog_process_status,
        'stdout': iverilog_process.stdout,
        'stderr': iverilog_process.stderr
    }


def execute_vvp():
    vvp_command = shlex.split("vvp simv")
    vvp_process = subprocess.Popen(vvp_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    try:
        vvp_process_status = vvp_process.wait(timeout=VVP_PROCESS.TIMEOUT_SECONDS)
    except:
        vvp_process_status = VVP_PROCESS.STATUS.TIMEOUT
        vvp_process.kill()

    return {
        'process': vvp_process,
        'status': vvp_process_status,
        'stdout': vvp_process.stdout,
        'stderr': vvp_process.stderr
    }


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-c', '--show-iverilog-command', action='store_true',
                        help="Print the iverilog command used")
    args = parser.parse_args()

    try:
        os.remove(GENERATED_SIMULATION_FILE)
    except FileNotFoundError:
        pass

    iverilog = execute_iverilog(args)

    if (iverilog['status'] != IVERILOG_PROCESS.STATUS.SUCCESS):
        print_iverilog_compilation_errors(iverilog['stderr'])
        exit(EXIT_STATUS.IVERILOG_PROCESS_COMPILATION_ERROR)

    vvp = execute_vvp()

    if (vvp['status'] == VVP_PROCESS.STATUS.TIMEOUT):
        print("Error: Simulation ran indefinitely for {} second{}".format(VVP_PROCESS.TIMEOUT_SECONDS,
                                                                          's' if VVP_PROCESS.TIMEOUT_SECONDS > 1 else ''), file=sys.stderr)
        exit(EXIT_STATUS.VVP_PROCESS_TIMEOUT)

    if (vvp['status'] == VVP_PROCESS.STATUS.SUCCESS):
        print_vvp_results(vvp['stdout'])
        exit(EXIT_STATUS.SIMULATION_SUCCESS)
