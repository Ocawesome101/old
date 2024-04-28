# ocpu
Everything related to my custom CPU emulator.

A web-based version of the emulator is located [here](https://scratch.mit.edu/projects/322195979/). The Python version (`ocpu.py`) requires `pygame`. It also doesn't quite seem to work on macOS for some reason.

My assembler's pretty basic, but it works.

`rom.asm` is the emulator's default ROM.

`ocasm` is the assembler. `ocasm.c` is a (broken) C version of it.

`insts.txt` is a list of instructions for the CPU, which is also embedded into the `ocasm` file. This will expand with time.

The OCPU is 16-bit, and uses groups of four instructions, like this:

```OpCode reg[0-7] DataH DataL```

The CPU has 8 registers, 4 instruction registers, and being 16-bit can access 64 kilobytes of RAM.

My emulator loads the ROM into memory, and then starts CPU execution. Anything further is controlled by the user.

With enough instructions, it probably would be possible to run something like FreeDOS on this thing.... Hmm. I'll think about it.

What would really be insane is if someone were to write an x86 emulator that works on this CPU, still has memory management, and runs DOS.
