#!/usr/bin/env python3
#
# This is the Python version of the OCPU emulator. It has its own limitations.
# Everything is software rendered, so it's pretty slow, but it works.
#
# Requires PyGame ('pip3 install pygame' or 'sudo apt-get install python-pygame'
# if you don't have it).

try:
    import pygame, sys, time
except:
    print('The OCPU emulator requires PyGame!')
    exit()

# Initialization functions
def mem_init(): # RAM initialization
    print('init memory')
    mem = []
    while len(mem) < 65536:
        mem.append('0000')
    print(str(len(mem)) + ' bytes in memory')
    return mem

def dmem_init(): # VRAM initialization
    print('init display memory')
    dmem = []
    while len(dmem) != 24000:
        dmem.append('00')
    print(str(len(dmem)) + ' pixels in display memory')
    return dmem

# Hexadecimal to decimal converter. Not very pretty, but it does the job.
# Expandable with some slight modifications
def getdecofhex(hex16):
    print('hex to dec', str(hex16))
    digits = [hex16[0],hex16[1],hex16[2],hex16[3]]
    m = 1
    print('multiplier = 1')
    i = 3
    rtn = 0
    while i > -1:
        print('get dec of hex digit')
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
        print('multiplier *= 16')
        print('shift to next hex digit')
        i -= 1
    print('got', str(rtn))
    return rtn

# This cheats - the OCPU has 8 registers.
def getdecofreg(regid):
    return int(regid[1])

# Instruction functions
def ldr(reg, reg2):
    print('ldr', reg, reg2)
    decreg = getdecofreg(reg)
    decreg2 = getdecofreg(reg2)
    regs[decreg] = regs[decreg2]

def ldm(reg, mem):
    print('ldm', reg, mem)
    memdec = getdecofhex(mem)
    regdec = getdecofreg(reg)
    regs[regdec] = mem[memdec]

def ld(reg, val):
    regdec = getdecofreg(reg)
    valdec = getdecofhex(val)
    regs[regdec] = valdec

def st(reg, mem):
    regdec = getdecofreg(reg)
    memdec = getdecofhex(mem)
    memory[memdec] = regs[regdec]

def std(val, mem):
    memdec = getdecofhex(mem)
    dmemory[memdec] = val

# Instruction parser
def parse_inst(inst):
    print('parse instructions ' + inst)
    inst_regs = ['','','','']
    print('clear inst_regs')
    i = 0
    t = 0
    inst = inst[0:len(inst)-1] + ' '
    while t < 4:
        print('get inst ' + str(t))
        while inst[i] != ' ':
            inst_regs[t] += inst[i]
            i += 1
        i += 1
        t += 1
    print('try exec',inst_regs)
    if inst_regs[0] == '00':
        print('ldr')
        ldr(inst_regs[1], inst_regs[3])
    elif inst_regs[0] == '01':
        print('ldm')
        ldm(inst_regs[1], inst_regs[2] + inst_regs[3])
    elif inst_regs[0] == '02':
        print('ld')
        ld(inst_regs[1], inst_regs[2] + inst_regs[3])
    elif inst_regs[0] == '10':
        print('st')
        st(inst_regs[1], inst_regs[2] + inst_regs[3])
    elif inst_regs[0] == '11':
        print('std')
        std(inst_regs[1], inst_regs[2] + inst_regs[3])
    elif inst_regs[0] == 'FF':
        print('halt')
        time.sleep(1)
        pygame.quit()
#        print('memory dump')
#        print(memory)
#        print('dmemory dump')
#        print(dmemory)
        sys.exit(0)
    elif inst_regs[0] == 'FE':
        print('noop')

#                    |
#                   \_/
def disp_update(): # Display update function
    print('update display')
    i = 0
    x,y = 0,0
    while i < len(dmemory):
        if dmemory[i] == '01':
            #print(str(x),str(y))
            color = white
        else:
            color = black
        pygame.Surface.set_at(screen,(x,y),color)
        if x == 239:
            x = 0
            y += 1
        else:
            x += 1
        i += 1
    pygame.display.update()

# The master function
def init():
    pygame.init()

    size = width, height = 240, 100

    global black
    black = 0, 0, 0
    
    global white
    white = 255, 255, 255
    
    global screen
    screen = pygame.display.set_mode(size)
    global regs
    regs = ['','','','','','','','']
    global memory
    memory = mem_init()
    global dmemory
    dmemory = dmem_init()

    if len(sys.argv) < 2:
        print('Usage: ocpu [file]')
        sys.exit(1)

    infile = open(sys.argv[1],'r')

    for line in infile:
        parse_inst(line)
        print('memory 0 is',memory[0])
        if memory[0] == 1:
            disp_update()
            memory[0] = '0000'

init() # Start
