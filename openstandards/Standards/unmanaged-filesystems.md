# Unmanaged filesystems


### Note: This documentation is outdated, and will be deleted soon. Check Standards/OpenUPT/OpenUPT.md for an up-to-date specification.

The unmanaged drive component in OpenComputers is incredibly versatile, and extends the mod's hard disk drives' capabilities to a great extent. However, there is currently no standard in place for writing filesystems using these components.

This standard attempts to encompass most general use cases for unmanaged-mode filesystems.

## Booting

Drives should have a boot sector on sector 1. This sector, when loaded and executed by the BIOS, should load the rest of the system.

Bootloaders should be stored on sectors 2 through 24. Filesystem drivers, if they can't be squeezed into 11.5 kilobytes, should be placed on the boot partition.

## Partitions

The partition table should sit on sector 25. Each partition's data should contain at least the following:

Bytes 1-4: Start sector, little-endian (4 bytes)

Bytes 5-8: End sector, little-endian (4 bytes)

Bytes 9-16: filesystem type (`OPENFS`, `FOXFS`, etc.) (8 bytes)

Bytes 17-20: Partition flags (4 bytes)

Bytes 21-28: Partition GUID (8 bytes)

Bytes 29-32: Reserved (4 bytes)

Bytes 33-64: Partition name (32 bytes)



Sectors 26-31 should be reserved.

Partition data starts at sector 32 and extends to the end of the drive.

## RAIDs

RAID support is an optional filesystem feature. If you do choose to implement it whilst still conforming to these standards, these are the guidelines you must follow.

Partition tables must be stored only on the first disk in an array, extending from sectors 25 to 31. This should allow for as many partitions as needed.

Files must have the ability to be split across drives, and in size be as large as the entire RAID (minus sectors 1 through 31).
