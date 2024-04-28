#!/usr/bin/env python3
#
# The OCPU emulator

import sys

try:
 import pygame
except ImportError:
 print("The OCPU emulator requires PyGame to be installed!")
 exit()

try:
 import emu_utils
except ImportError:
 raise ImportError("emu_utils.py does not appear to be present")
 exit()


class Memory:
 def __init__(self, amount):
  self.data = [0x0000]*amount

 def read(self, hex_address):
  converted = int(hex_address)
  if converted > len(self.data):
   print("WARNING: Attempt to read from invalid address " + str(hex_address))
   return 0

  return self.data[converted]

 def write(self, hex_address, hex_data):
  converted = int(hex_address)
  if converted > len(self.data):
   print("WARNING: Attempt to write to invalid address " + str(hex_address))
   return 0

  self.data[converted] = hex_data


class Display:
 def __init__(self, vram_amount):
  pygame.init()

  self.dmem = Memory(vram_amount)

  dsize = emu_utils.display_size(vram_amount)
  self.dsize = self.width, self.height = dsize[0], dsize[1]

  self.screen = pygame.display.set_mode(self.dsize)

 def update(self):
  x, y, i = 0, 0, 0
  while y < self.height:
   while x < self.width:
    pygame.Surface.set_at(self,screen, x, y, emu_utils.color(self.dmem[i]))
    i += 1
    x += 1
   y += 1

  pygame.display.update()

 def clear(self):
  self.dmem = Memory(len(self.dmem))

 def set(self, hex_addr, hex_value):
  self.dmem.write(hex_addr, hex_value)


class Registers:
 def __init__(self, hex_ram_amount, hex_vram_amount, hex_rom_amount):
  self.data = [0x0000]*0x0D
  self.data[0x09] = hex_vram_amount
  self.data[0x0A] = hex_ram_amount
  self.data[0x0B] = hex_rom_amount

 def write(self, reg, data):
  if int(reg) < 9:
   self.data[int(reg)] = data
  else:
   print("WARNING: Attmept to write to locked register", reg)

 def read(self, reg):
  return self.data[int(reg)]

 def add(self, reg, data):
  self.data[int(reg)] += data
  self.data[int(reg)] = hex(self.data[int(reg)])

 def sub(self, reg, data):
  self.data[int(reg)] -= data
  self.data[int(reg)] = hex(self.data[int(reg)])


def main(mem_amount, vmem_amount, romfile): # Master (and monster) function
 print("Init registers")
 regs = Registers(mem_amount, vmem_amount, 65535 - (mem_amount + vmem_amount)) # Initialize registers

 print("Init mem", mem_amount)
 sys_mem = Memory(mem_amount) # Initialize RAM

 print("Init display", vmem_amount)
 display = Display(vmem_amount) # Init display

 # Instruction function definitions
 def load(reg, dataH, dataL):
  full_data = emu_utils.concat_hex(dataH, dataL)
  regs.write(reg, full_data)

 def store(reg, addrH, addrL):
  full_addr = emu_utils.concat_hex(addrH, addrL)
  if full_addr <= mem_amount:
   sys_mem.write(full_addr, regs.read(reg))
  elif full_addr <= mem_amount + vmem_amount:
   display.set(regs.read(reg), full_addr - (mem_amount))
  elif full_addr <= (65535 - (mem_amount + vmem_amount)):
   print("ERROR: Cannot write to ROM")

 def add(reg, reg2):
  regs.add(reg, regs.read(reg2))

 def sub(reg, reg2):
  regs.sub(reg, regs.read(reg2))

 def mov(reg, reg2):
  regs.write(reg2, regs.read(reg))
  regs.write(reg, 0x0000)

 def ifeq(reg, dataH, dataL):
  full_data = emu_utils.concat_hex(addrH, addrL)
  if regs.read(reg) == full_data:
   return True
  else:
   return False

 def neq(reg, dataH, dataL):
  if ifeq(reg, dataH, dataL):
   return False
  else:
   return True

 def noop():
  print("NOOP")

 # Parser functions
 exec_line = True
 def parse_inst(inst, arg1, arg2, arg3):
  print(inst, arg1, arg2, arg3)
  if inst == 0x00:
   print("load", arg1, arg2, arg3)
   load(arg1, arg2, arg3)
  elif inst == 0x10:
   print("store", arg1, arg2, arg3)
   store(arg1, arg2, arg3)
  elif inst == 0x20:
   print("add", arg1, arg3)
   add(arg1, arg3)
  elif inst == 0x30:
   print("sub", arg1, arg3)
   sub(arg1, arg3)
  elif inst == 0x40:
   print("move", arg1, arg3)
   mov(arg1, arg3)
  elif inst == 0x80:
   print("ifeq", arg1, arg2, arg3)
   exec_line = ifeq(arg1, arg2, arg3)
  elif inst == 0x81:
   print("neq", arg1, arg2, arg3)
   exec_line = neq(arg1, arg2, arg3)
  elif inst == 0xFF:
   print("System halt")
   sys.exit()
  else:
   noop()

 def parse_rom(file):
  data = emu_utils.read_rom(file)
  i, j = 0, 0
  while True:
   i = j
   j += 4
   inst_ln = [0x00,0x00,0x00,0x00]
   while i < j:
    inst_ln.append(sys_mem.read(i))
    i += 1

   if exec_line == True:
    parse_inst(inst_ln[0], inst_ln[1], inst_ln[2], inst_ln[3])

 parse_rom(romfile)

if __name__ == "__main__":
 args = sys.argv

 vmem = 8192
 mem = 24576

 if len(args) <= 1:
  print("Usage:", args[0], "<romfile> [--mode 0|1|2|3|4]")
  exit()

 romfile = args[1]

 if len(args) == 3:
  if args[3] == "0":
   vmem = 4096
   mem = 8192
  elif args[3] == "1":
   vmem = 8192
   mem = 8192
  elif args[3] == "2":
   vmem = 8192
   mem = 24576
  elif args[3] == "3":
   vmem = 16384
   mem = 32768
  elif args[3] == "4":
   vmem = 8192
   mem = 49152

 main(mem, vmem, romfile)
