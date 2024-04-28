-- A fairly minimal BIOS. Provides error() and loadfile() and loads /boot/kernel.img --

function error(reason)
  local w,h = term.getSize()
  term.setCursorPos(1,h)
  term.setTextColor(16384)
  term.write(reason)
  while true do
    coroutine.yield()
  end
end

-- Replicate some of the OpenComputers "computer" API
_G.computer = {}

function computer.pullSignal()
  return coroutine.yield()
end

function computer.shutdown(reboot)
  if reboot then
    os.reboot()
  else
    os.shutdown()
  end
  while true do
    coroutine.yield()
  end
end

function loadfile(file)
  local handle = fs.open(file, "r")
  if not handle then
    return false, "file not found"
  end
  local data = handle.readAll()
  handle.close()
  return loadstring(data, "@" .. file, "bt", _G)
end

local ok, err = loadfile("/boot/kernel.lua")
if not ok then
  error(err)
end
local status, returned = pcall(ok)
if not status then
  error(returned)
else
  computer.shutdown()
end
