#!/usr/bin/python3
import requests
from subprocess import check_output

#---------------------------------------------
def read_proc_stats(file):
  cpu_stat = open("/proc/"+file, "r")
  raw = cpu_stat.read()
  cpu_stat.close()
  return raw.replace("\r","").split("\n")

#---------------------------------------------
def clean_row(line):
  line = line.replace(" ","").replace("kB","")
  return int(line.split(":")[1])

#---------------------------------------------
def get_mem():
  raw = read_proc_stats("meminfo")
  meminfo = {
    "max" : clean_row(raw[0]),
    "free" : clean_row(raw[1])
  }
  meminfo["used"] = meminfo["max"] - meminfo["free"]
  return meminfo

#---------------------------------------------
def get_cpus():
  raw = read_proc_stats("stat")
  stat = {}
  for line in raw:
    if "cpu" not in line:
      continue
    line = line.replace("  "," ").split(" ")
    stat[line[0]] = {
      "active" : int(line[1]) + int(line[3]),
      "cycles" : int(line[1]) + int(line[3]) + int(line[4]),
    }
  return stat

#---------------------------------------------
def get_temps():
  temp = check_output(["/opt/vc/bin/vcgencmd", "measure_temp"])
  temp = temp.decode("utf-8").replace("\n","")
  return temp.split("=")[1]

#---------------------------------------------
data = {
  "mem_info" : get_mem(),
  "cpu_info" : get_cpus(),
  "temps" : get_temps()
}

res = requests.post('http://home.osf/api/stats/send', json = data);