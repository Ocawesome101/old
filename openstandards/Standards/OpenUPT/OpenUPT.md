# OpenUPT

OpenUPT is a format that allows for partitioning and booting of unmanaged disks.

## Sector Layout

Sectors in an OpenUPT-formatted drive should be laid out and used for the following purposes:

Sector 1: The boot sector. This contains up to 512 bytes of Lua code that will be executed upon booting this disk. If a disk is not meant to be booted, the code contained in this sector should just be a stub that prints an error, such as "Non bootable disk. Press any key to reboot."

Sectors 2-24: These sectors are reserved for use by the bootloader. Usually, these sectors contain executable code for the boot sector to run. If there isn't a bootloader installed, or these sectors aren't needed, they should be left blank.

Sector 25: The partition table. This sector contains 8 64-byte entries describing partitions on this drive. The details of this are in the "Partition Table" section.

Sectors 26-32: Reserved for future use.

Sectors 33-end of disk: The actual data on the disk.

## Partition Table

The partition table is 512 bytes (1 sector) in size, and holds 8 64-byte entries. This means there can be a maximum of 8 partitions on one drive. An entry in the table has this format:

Bytes 1-4: Start sector (4 bytes)

Bytes 5-8: End sector (4 bytes)

Bytes 9-16: FS type (8 bytes)

Bytes 17-20: Partition flags (4 bytes)

Bytes 21-28: Partition GUID (8 bytes)

Bytes 29-32: Reserverd space (4 bytes)

Bytes 33-64: Partition label (32 bytes)
