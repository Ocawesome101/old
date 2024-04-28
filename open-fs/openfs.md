# OpenFS spec

OpenFS is a fairly simple file system for the OpenComputers Minecraft mod.

The minimum file size is 0, and the minimum directory size is 4096. Maximum allocable drive size is 16MB.

OpenFS assumes that drive sector size is 512 bytes.

The master file table is stored in sectors 1-128. It is formatted as such:

```lua
-- Beginning of table
{
  ["/init.lua"] = {
    type = "file",
    startSector = 129,
    size = 1072
  },
  ["/bin"] = {
    type = "directory",
    subNodes = {
      ["/bin/sh.lua"] = {
        type = "file",
        startSector = 131,
        size = 2076
      }
    }
  },
  ...
}
```

The master table is stored as a series of bytes which, when `string.char`ed and concatenated, can be unserialized.

There should, as a general rule, be at least one blank (0) byte between files. A bootloader should fit into sector 0.

An OpenFS driver implementation MUST provide:

```lua
_G.openfs
openfs.open(file:string[, mode='r']): handle[:read, :write, :close]
openfs.makeDirectory(directory:string): success:boolean
openfs.exists(file:string): exists:boolean
openfs.remove(file:string[, recursive:boolean]): success:boolean
openfs.getLabel(): label:string
openfs.setLabel(label:string): newLabel:string
openfs.getCapacity(): totalCapacity:number
```

All of the above are implemented in the reference driver.

Optional provisions include:
```lua
openfs.permissions(file:string): permissions:string
openfs.setPermissions(file:string, posixPermissions:string): success:boolean
openfs.isReadOnly(file): isReadOnly:boolean
openfs.lastModified(file): time:number
```

These are up to the driver to implement, however, and should not be relied upon.
