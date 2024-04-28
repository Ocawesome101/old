# open-kernel-computercraft
An alternate kernel and read function to make Open Kernel work on ComputerCraft.

This has only been tested with the BIOS I've included in this Git repository. If it works on regular CC (probably won't) it wasn't on purpose.

# Instructions
On your ComputerCraft installation:
Replace `/boot/kernel.lua` with the one in this repo, and place `80_read.lua` in `/etc/init.d`. Place the custom BIOS at `.minecraft/resourcepacks/<any resourcepack>/assets/computercraft/lua/bios.lua`.
