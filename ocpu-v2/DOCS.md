# OCPU v2

This is the second iteration of the OCPU emulator. It is significantly more
advanced than the first, with features such as a stack and a heap. It 
supports 32K of RAM and 32K of ROM.

An up-to-date instruction table can be found [here.](https://docs.google.com/document/d/11FbpA9ceh6ECukTBZRbXM9y_Jgz3DdQ41wl5f4RTN8I/edit)

### Basic features

The OCPU emulator has access, by default, to 32 kilobytes of both RAM 
and ROM. This is configurable, however; by running with the --memmode 
flag, where modes are:

 - 0: 4K of VRAM, 8K of RAM, and 54K of ROM
 - 1: 8K of VRAM and RAM, 48K of ROM
 - 2: 8K of VRAM, 24K of RAM, 32K of ROM (default)
 - 3: 32K of RAM, 16K of VRAM, and 16K of ROM
 - 4: 48K of RAM, 8K of VRAM, and 8K of ROM

A warning: Programs compiled for one mode may not work if they try to 
access memory outside of the current configuration; i.e. a program 
written to use 32K of RAM may not work in a 16K environment-- this 
simply depends on how much memory the program actully uses.

The stack is as yet non-functional, but should once 
implemented be roughly equivalent to the x86/ARM version.

Registers 09, 0A, and 0B are set to fixed values equal to the amount of 
VRAM/RAM/ROM in your system; for the default configuration, r09=0x0008, 
r0A=0x0018, and r0B=0x0020.

### Other hardware

This emulator does not only emulate a CPU, It emulates a video card, 
display, and keyboard as well.

The provided video card will constantly read from the end of the memory 
address space (the amount being defined by the memory mode; default 
8k), and if, but only if, register 0x10 is set to 0x0001 will update 
the screen.

This emulator assumes that the CPU, video card, and keyboard are all 
directly attached. The keyboard controller interfaces with register 0C, 
setting it to the value of the last key pressed.

### Programming

You may be wondering how you can program for this processor.

A fairly full-featured assembler will be available to convert something 
like 'LD 04 AB CD' into '00000000 00000100 10101011 11001101' and write it 
to a binary file.

I will also be releasing a full programming language for the OCPU v2. If 
all goes to plan, it will be similarly low-level to C, but with a fairly 
simple, comprehensive syntax similar to Python.

I might attempt to write an OS for the OCPU, but this is dependent on a 
number of things:

1) That I can even figure out where to start

2) That I have the motivation to finish it

3) That the instruction set is Turing complete

4) I manage to write everything and have the compiled binary fit inside 
32K (given the small OS it hopefully won't be that hard).

### Planned features

A stack of 512 bytes in size (maybe)

Some kind of virtual I/O (such as a removable segment of the ROM) to 
allow saving files created in the emulator

A programming language or assembler of some sort
