#!/usr/bin/env python3
#
# This is a compiler for a simple programming language. It compiles down to OCPU
# assembly, so you will need to have my OCPU Emulator if you don't already.
#
# Documentation of the language can be found at:
# https://oz-craft.pickardayune.com/ocpu/programming/

import sys

# Hexadecimal to decimal converter
def getdecofhex(hex16):
#    print('hex to dec', str(hex16))
    digits = [hex16[0],hex16[1],hex16[2],hex16[3]]
    m = 1
#    print('multiplier = 1')
    i = 3
    rtn = 0
    while i > -1:
#        print('get dec of hex digit')
        d = digits[i].lower()
        if d == 'a':
            rtn += 10*m
        elif d == 'b':
            rtn += 11*m
        elif d == 'c':
            rtn += 12*m
        elif d == 'd':
            rtn += 13*m
        elif d == 'e':
            rtn += 14*m
        elif d == 'f':
            rtn += 15*m
        else:
            rtn += int(d)*m
        m = m*16
#        print('multiplier *= 16')
#        print('shift to next hex digit')
        i -= 1
#    print('got', str(rtn))
    return rtn

# Decimal to hexadecimal converter
def gethexofdec(dec):
    h = hex(int(dec))[2:len(hex(dec))]
    while len(h) < 4:
        h = '0' + h
    return h

# Simple function to split a string into words, separated by the space character
def get_words(line):
#    print('get wd', line)
    i = 0
    l = len(line) - 2
    rtn = []
    n = 0
    while True:
        rtn.append('')
        while line[i] != ' ':
            rtn[n] += line[i].lower()
            if i < l:
                i += 1
            else:
                break
        i += 1
        if i < l:
            n += 1
        else:
            break
#    print('got',rtn)
    return rtn

# Get number of x and y coords
def getxy(x,y):
    add_me = y*298
    result = gethexofdec(x + add_me)
    print(result)
    return result[0:2],result[2:4]

def interpret_hex(val):
    result = gethexofdec(int(val))
    return result[0:2] + ' ' + result[2:4]

# Line parser
def parse_line(line):
    words = get_words(line)
    rtn = []
    if words[0] == 'clear':
        i = 0
        while len(rtn) < 24000:
            rtn.append('11 ' + words[1] + ' ' + interpret_hex(i) + '\n')
            i += 1
    elif words[0] == 'setpx': # syntax: setpx <px> <8 bit hex>
        if int(words[1]) > 23900:
            raise IndexError('pixel index too large')
        else:
            x = interpret_hex(words[1])
            rtn.append('11 ' + words[2] + ' ' + x + '\n')
    elif words[0] == 'halt':
        rtn.append('FF 00 00 00\n')
    elif words[0] == 'noop':
        rtn.append('FE 00 00 00\n')
    elif words[0] == 'store': # Usage: store <0-7> <0-65535>
        if int(words[1]) > 7:
            raise IndexError('reg addr too big')
        if int(words[2]) > 65535:
            raise IndexError('mem addr too big')
        reg = '0' + words[1]
        mem_addr = interpret_hex(words[2])
        rtn.append('10 ' + reg + ' ' + mem_addr + '\n')
    elif words[0] == 'setreg': # Usage: setreg <0-7> <numerical value>
        reg = '0' + words[1]
        val = interpret_hex(words[2])
        rtn.append('02 ' + reg + ' ' + val + '\n')
    elif words[0] == '\n':
#        print('blank line detected - insert noop')
        rtn.append('FE 00 00 00\n')
    elif words[0][0] == ';':
#        print('comment detected - insert noop')
        rtn.append('FE 00 00 00\n')
    else:
        raise AssertionError('Unrecognized word ' + words[0])
    return rtn

if len(sys.argv) < 2:
    print('Usage: occ <FILE> [OUT]')
    sys.exit()

infile = open(sys.argv[1],'r')

outname = 'occ.oca'

if sys.argv[2]:
    outname = sys.argv[2]

outfile = open(outname,'w')

for line in infile:
    out = parse_line(line)
#    print('out is', out[0].upper())
    for i in out:
        outfile.write(i.upper())

outfile.close()
