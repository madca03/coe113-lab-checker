import subprocess
import shlex
import os
import time

if __name__ == '__main__':
  try:
    os.remove("simv")
  except FileNotFoundError:
    pass

  tb_file = 'tb_single_cycle_mips.v'
  compile_command = "iverilog -o simv {} ../rtl/*.v ../memory/*.v".format(tb_file)
  compile_command = shlex.split(compile_command)
  
  p = subprocess.Popen(compile_command, stdout=subprocess.PIPE)
  p_status = p.wait()

  vvp_command = shlex.split("vvp simv")
  with subprocess.Popen(vvp_command, stdout=subprocess.PIPE) as proc:
    for line in proc.stdout:
      line = line.decode()
      if "WARNING" in line or "VCD info" in line or "data memory" in line:
        continue

      line = line.strip().split(" ")
      line = list(filter(lambda x : len(x), line))
      line = "{} {} {}{}".format(line[0], line[1], line[2], line[3])
      print(line)