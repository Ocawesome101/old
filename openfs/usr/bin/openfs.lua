-- openfs utility. Designed to work with openUPT --

package.loaded.openfs = nil
local upt = require("openupt")
local drv = require("openfs")

local inodePattern = "<c32I1I8c3c15c443I4"

local args, opts = require("shell").parse(...)

local drive = require("component").list("drive", true)()
print("Using drive " .. drive)
upt.select(drive)

local function err(...)
  io.stderr:write(..., "\n")
  os.exit(1)
end

local usage = [[usage: openfs OPTIONS
options:
  --format --id=<id>                    format an OpenUPT partition with OpenFS
  --mount  --id=<id> --path=<path>      mount an OpenFS partition <id> at <path>]]

if opts.help then
  err(usage)
elseif opts.format then
  if not (opts.id and tonumber(opts.id)) then
    err("missing one of, or invalid: id")
  end
  local id = tonumber(opts.id)
  local partinfo = upt.getPartitions()
  print(partinfo[id].start)
  require("component").invoke(drive, "writeSector", partinfo[id].start, string.pack(inodePattern, "/", 1, 0, string.unpack("<I3", string.pack("<I1I1I1", 5, 5, 5)), "root", "", 0))
elseif opts.mount then
  if not (opts.id and tonumber(opts.id) and opts.path and type(opts.path) == "string") then
    err("missing one of, or invalid: id, path")
  end
  local id = tonumber(opts.id)
  local path = opts.path
  local new = upt.new(id, drv)
  require("filesystem").mount(new, path)
end