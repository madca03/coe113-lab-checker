#!/usr/bin/python3
import subprocess
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

  TIMEOUT_SECONDS = 1 # allowable simulation time

class IVERILOG_PROCESS:
  class STATUS:
    SUCCESS = 0

GENERATED_SIMULATION_FILE = "simv"
SINGLE_CYCLE_MIPS_TESTBENCH_INSTANCE_NAME = "UUT"
SINGLE_CYCLE_MIPS_MODULE_NAME = "single_cycle_mips"

def print_iverilog_compilation_errors(process_stderr):
    missing_ports = []
    
    with process_stderr as f:
      for line in f:
        line = line.decode().strip()
        if "not a port of {}".format(SINGLE_CYCLE_MIPS_TESTBENCH_INSTANCE_NAME) in line:
          search_str = "``"
          index = line.find(search_str)
          port = line[index + len(search_str):]

          search_str = "''"
          index = port.find(search_str)
          port = port[:index]

          missing_ports.append(port)

    if len(missing_ports):
      for port in missing_ports:
        print("Missing {0} port in {1}.v module".format(port, SINGLE_CYCLE_MIPS_MODULE_NAME), file=sys.stderr)

def print_vvp_results(process_stdout):
  with process_stdout as f:
    for line in f:
      line = line.decode().strip()
      if "WARNING" in line or "VCD info" in line or "data memory" in line:
        continue

      line = list(filter(lambda x : len(x), line.split(" ")))
      line = "{} {} {}{}".format(line[0], line[1], line[2], line[3])
      print(line)

def execute_iverilog():
  verilog_files = [f for f in os.listdir('.') if os.path.isfile(f) and f.endswith('.v')]
  verilog_files = ' '.join(verilog_files)

  iverilog_command = "iverilog -o {0} {1}".format(GENERATED_SIMULATION_FILE, verilog_files)
  iverilog_command = shlex.split(iverilog_command)
  
  iverilog_process = subprocess.Popen(iverilog_command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
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
    vvp_process_status = vvp_process.wait(timeout = VVP_PROCESS.TIMEOUT_SECONDS)
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
  try:
    os.remove(GENERATED_SIMULATION_FILE)
  except FileNotFoundError:
    pass

  iverilog = execute_iverilog()

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