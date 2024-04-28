-- init process --

local component, computer, kernel = component, computer, kernel
_G.computer, _G.component = nil, nil -- get these blasted things outta my global env

kernel.logger.progress(70)
kernel.logger.log("load drivers")

local fs = kernel.bootfs

local config = fs.open("/cfg/drivers.cfg")
if not config then
  kernel.panic("failed to load drivers.cfg")
end

local temp = "return "
repeat
  local chunk = fs.read(config, math.huge)
  temp = temp .. (chunk or "")
until not chunk
fs.close(config)

local ok, err = load(temp, "=drivers.cfg", "t", {})
if not ok then
  kernel.panic(err)
end

local driversandbox = setmetatable({
  component = component,
  computer = computer,
  kernel = kernel
}, {__index=_G})

local cfg = ok()
for i=1, #cfg, 1 do
  local k,v = cfg[i].name, cfg[i].file
  if fs.exists(v) then
    kernel.logger.log("driver:", k)
    local handle = fs.open(v)
    local temp = ""
    repeat
      local chunk = fs.read(handle, math.huge)
      temp = temp .. (chunk or "")
    until not chunk
    fs.close(handle)

    -- metatables are wonderful things
    local ok, err = load(temp, "=" .. v, "t", setmetatable({}, {__index=driversandbox}))
    if not ok then
      kernel.panic(err)
    end
    local function start()
      kernel.thread.spawn(ok, "drv_" .. k, kernel.panic, {interrupt=true})
    end
    start()
  else
    kernel.panic("driver", k, "nonexistent")
  end
end
coroutine.yield() -- let drivers initialize

kernel.logger.progress(80)
kernel.logger.log("load io")

function _G.loadfile(file, mode, env)
  checkArg(1, file, "string")
  local con, err = ipc.channel("drv_filesystem")
  if not con then
    return nil, err
  end
  con:write("open", file, "r")
  local handle, err = con:read()
  if not handle then
    return nil, err
  end
  local temp = ""
  repeat
    con:write("read", handle, math.huge)
    local chunk, err = con:read()
    if not chunk and err then
      return nil, err
    end
    --kernel.logger.log(chunk)
    temp = temp .. (chunk or "")
  until not chunk
  con:wait("close", handle)

  return load(temp, "=" .. file, "bt", _G)
end

local ok, err = loadfile("/micro/lib/io.lua")
if not ok then
  error(err)
end
local s, r = pcall(ok)
if not s and r then
  error(r)
end

kernel.logger.progress(90)
kernel.logger.log("load package")
local ok, err = loadfile("/micro/lib/package.lua")
if not ok then
  error(err)
end
local s, r = pcall(ok)
if not s and r then
  error(r)
end

kernel.logger.progress(100)
kernel.logger.log("start shell")

local ok, err = loadfile("/micro/shell.lua")
if not ok then
  error("shell: " .. err)
end
_G.kernel = nil

while true do
  coroutine.yield()
  if not kernel.thread.find("shell") then
    kernel.thread.spawn(ok, "shell")
  end
end
