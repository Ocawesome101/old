-- init me up, Scotty --

local component = component
local computer  = computer
local k         = kernel
local unicode   = unicode
local sched     = scheduler
local loadfile  = loadfile

k.log("Start init")

k.log("Inject syscalls: spawn, spawnfilw")
k.progress(55)

-- ALL system calls will return whatever results and the results of coroutine.yield
function _G.spawn(...)
  return sched.spawn(...), coroutine.yield()
end

function _G.spawnfile(file, ...)
  checkArg(1, file, "string")
  local ok, err = loadfile(file)
  if not ok then
    error(err)
  end
  return sched.spawn(ok, file, ...), coroutine.yield()
end

k.log("Start driver auto-reload process")
k.progress(50)

spawnfile("/l4/drv/auto_reload.lua")
coroutine.yield(0)

k.log("Finish syscalls")
k.progress(80)

local ok, err = loadfile("/l4/calls.lua")
if not ok then
  error(err)
end

ok()

k.log("Load io and package libraries")
k.progress(86)

local ok, err = loadfile("/l4/core/package.lua")
if not ok then
  error(err)
end

ok()

k.progress(92)

local ok, err = loadfile("/l4/core/io.lua")
if not ok then
  error(err)
end

ok()

k.log("Start shell")

k.progress(100)

spawnfile("/exec/shell.lua")

while true do
  coroutine.yield()
end
