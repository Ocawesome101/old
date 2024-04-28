-- System/101 kernel --

local root_loadfile, bootfs_addr = ...

_G._OSVERSION = "System/101 0.1.0a1"

-- boot logging: API-dependent!
local status
do
  local component = component
  local screen, gpu = component.list("screen", true)(), component.list("gpu", true)()
  if screen and gpu then
    component.invoke(gpu, "bind", screen)
  end
  local y = 1
  local w, h
  status = function(msg)
    if screen and gpu then
      if not (w and h) then
        w, h = component.invoke(gpu, "maxResolution")
        component.invoke(gpu, "setResolution", w, h)
        component.invoke(gpu, "setForeground", 0xFFFFFF)
        component.invoke(gpu, "setBackground", 0x000000)
        component.invoke(gpu, "fill", 1, 1, w, h, " ")
      end
      component.invoke(gpu, "set", 1, y, tostring(msg))
      y = y + 1
      if y > h then
        y = h
        component.invoke(gpu, "copy", 1, 1, w, h, 0, -1)
        component.invoke(gpu, "fill", 1, h, w, 1, " ")
      end
    end
  end
end

status("Starting " .. _OSVERSION)

-- low-level loadfile/dofile until we get a proper filesystem interface
_G.loadfile = root_loadfile
function dofile(file, ...)
  local call = assert(root_loadfile(file))
  local status, ret = assert(xpcall(call, debug.traceback, ...))
  return ret
end

status("Loading base filesystem library...")
_G.filesystem = dofile("/system101/lib/filesystem.lua", status, bootfs_addr)

filesystem.mount(bootfs_addr, "/")

status("Loading package library...")
local package = dofile("/system101/lib/package.lua")

-- clean up the global environment a bit
_G.component  = nil
_G.computer   = nil
_G.filesystem = nil
_G.unicode    = nil

_G.package = package
_G.io = require("io")

status("Running boot scripts...")
local files = require("filesystem").list("/system101/startup/")
table.sort(files)
for i=1, #files, 1 do
  status("> "..files[i])
  dofile("/system101/startup/"..files[i], status)
end

while true do require("computer").pullSignal() end
