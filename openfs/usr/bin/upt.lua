-- OpenUPT utility. Should, in theory, work in anything with the required APIs. --

local upt = require("openupt")
local shell = require("shell")
local fs = require("filesystem")

local _, opts = shell.parse(...)

local drive = require("component").list("drive", true)()
print("Using drive " .. drive)
upt.select(drive)

local function err(...)
  io.stderr:write(..., "\n")
  os.exit(1)
end

local help = [[options:
  --create --size=<size> --start=<start> --type=<type>
  --delete --id=<id>
  --list
  --format [--file=<file>]
  --bootsector --file=<file>]]

if opts.help then
  err(help)
elseif opts.create then
  if not (opts.size and opts.start and opts.type and type(opts.type) == "string") then
    err("missing one of: size, start, type")
  end
  local ok, err = upt.addPartition(tonumber(opts.start), tonumber(opts.start) + tonumber(opts.size), opts.type)
  if not ok then
    err(err)
  end
  return ok
elseif opts.delete then
  if not opts.id then
    err("missing one of: id")
  end
  local ok, err = upt.delPartition(tonumber(opts.id))
  if not ok then
    err(err)
  end
  return ok
elseif opts.list then
  local parts = upt.getPartitions()
  for i=1, #parts, 1 do
    local p = parts[i]
    print(
      string.format("partition %d:\n  Start sector: %d\n  End sector: %d\n  Type: '%s'\n  Label: '%s'\n  GUID: %s",
        i,
        p.start,
        p["end"],
        p.type,
        p.label,
        p.guid
      )
    )
  end
elseif opts.format then
  local b
  if opts.file and type(opts.file) == "string" then
    if not fs.exists(opts.file) then
      err(opts.file .. ": file not found")
    elseif fs.isDirectory(opts.file) then
      err(opts.file .. ": is a directory")
    end
    local handle, err = io.open(opts.file)
    b = handle:read(512)
    handle:close()
  end
  upt.format(b, opts.secure)
elseif opts.bootsector then
  local b
  if opts.file and type(opts.file) == "string" then
    if not fs.exists(opts.file) then
      err(opts.file .. ": file not found")
    elseif fs.isDirectory(opts.file) then
      err(opts.file .. ": is a directory")
    end
    local handle, err = io.open(opts.file)
    b = handle:read(512)
    handle:close()
  end
  return upt.bootsector(b)
elseif opts.bootloader then
  local b
  if opts.file and type(opts.file) == "string" then
    if not fs.exists(opts.file) then
      err(opts.file .. ": no such file or directory")
    elseif fs.isDirectory(opts.file) then
      err(opts.file .. ": is a directory")
    end
    local handle, err = io.open(opts.file)
    b = handle:read("*a")
    handle:close()
  else
    err("missing one of: file")
  end
  return upt.bootloader(b)
elseif opts.flashpart then
  local b
  if not (opts.id and opts.file) then
    err("missing one of: id, file")
  end
  if opts.file and type(opts.file) == "string" then
    if not fs.exists(opts.file) then
      err(opts.file .. ": file not found")
    elseif fs.isDirectory(opts.file) then
      err(opts.file .. ": is a directory")
    end
    local handle, err = io.open(opts.file)
    b = handle:read("*a")
    handle:close()
  end
  return upt.flashpart(tonumber(opts.id), b)
else
  err("usage: upt [options]\n", help)
end
