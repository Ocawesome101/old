# File storage

Boot sectors, RAID arrays, and partition tables were all discussed in the last

## Storing files

The nethod in which OpenFS stores files borrows from the UNIX implementation.

File index nodes (inodes) are stored in the beginning one percent of sectors of every partition. Each inode contains the corresponding file's starting sector, ending sector, and type (`0` or `1` for file or directory, respectively). Each of the inode sectors can allocate 32 files, equating to 2560 total allocable files on a 4-megabyte partition.

Inodes are formatted as such:
Bytes 1-32: File name (32 bytes)
Bytes 33-36: Parent inode (4 bytes, 0 if parent is root)
Bytes 37-38: File type (1 byte)
Bytes 39-42: Last modified (4 bytes)
Bytes 43-45: Permissions (3 bytes, owner-group-other, each byte 0-7)
Bytes 46-60: Owner (15 bytes, string)
Bytes 61-64: Starting sector (4 bytes)
