# A set of common utilities for the OCPU emulator and related scripts.

def base_romfile(size): # Return an empty bytearray that is the correct size for an OCPU ROM
 return bytearray([0xFE] * size)

def convert_to_rom(path_to_infile, path_to_outfile): # Convert a text file full of 0xABCDs into a binary file
 with open(path_to_infile, "r") as infile:
  with open(path_to_outfile, "wb") as outfile:
   for line in infile:
    for word in line:
     outfile.write(hex(line))

def write_rom(data, path):
 with open(path, "wb") as outfile:
  outfile.write(data)

def split_into_chars(string):
 rtn = []
 for char in string:
  rtn.append(char)

 return rtn

def reverse(string):
 rtn = ""
 n = len(string)-1
 while n > -1:
  rtn += string[n]
  n -= 1

 return rtn

def get_num(hex_char): # Convert a single hexadecimal digit to base 10
 chars = ['a','b','c','d','e','f'] # It works, don't question it
 n = 0
 for c in chars: # Probably really slow but it works
  if hex_char.lower() == c:
   return n + 10
  n += 1

 return int(hex_char)

def hex_to_int(hex_num): # Convert a hexadecimal number into an integer. Written before I realized that str(), int(), and hex() fit my needs perfectly.
 chars = hex_num
 if hex_num[0:2] == "0x":
  chars = hex_num[2:len(chars)]
 chars = split_into_chars(reverse(chars))

 result = 0
 multiply = 1
 i = 0
 for char in chars:
  multiply = 16**i
  num = int(get_num(char)) * multiply
  result += num
  i += 1

 return result

def color(self, hex16_color):
 if hex16_color == 0x0001:
  return (255,255,255)
 else:
  return (000,000,000)

def display_size(vram_amount):
 if vram_amount == 4096:
  return [80, 50]
 elif vram_amount == 8192:
  return [160, 50]
 elif vram_amount == 16384:
  return [280, 75]
 else:
  return [50, 50]

def read_rom(file):
 rtn = []
 with open(file, "rb") as romfile:
  for line in romfile:
   for word in line:
    rtn.append(word)

 return rtn

def concat_hex(num1, num2):
 rtn = num1 + num2
 tmp = str(hex(rtn))

 tmp = tmp[2:len(tmp)-1]

 while len(tmp) < 4:
  tmp = "0" + tmp

 rtn = int(tmp)

 print(rtn)
 return hex(rtn)
