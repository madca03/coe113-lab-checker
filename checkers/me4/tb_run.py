#!/usr/bin/python3
import os
import subprocess
import shlex

PYTHON_EXIT_STATUSCODE_SIMULATION_SUCCESS                   = 0
PYTHON_EXIT_STATUSCODE_VVP_PROCESS_TIMEOUT                  = 1
PYTHON_EXIT_STATUSCODE_IVERILOG_PROCESS_COMPILATION_ERROR   = 2

if __name__ == '__main__':
  command = "python run.py"
  command = shlex.split(command)
  p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  p_status = p.wait()

  print("status = {}".format(p_status))

  if (p_status == PYTHON_EXIT_STATUSCODE_SIMULATION_SUCCESS):
    with p.stdout as f:
      for line in f:
        line = line.decode().strip()
        print(line)

  elif (p_status == PYTHON_EXIT_STATUSCODE_IVERILOG_PROCESS_COMPILATION_ERROR or
        p_status == PYTHON_EXIT_STATUSCODE_VVP_PROCESS_TIMEOUT):

    with p.stderr as f:
      for line in f:
        line = line.decode().strip()
        print(line)
      