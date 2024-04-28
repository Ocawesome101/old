-- Automatically restart drivers when they die. Also provides a way for drivers to store information; i.e. the FS driver can store its mount info. --

local k     = kernel
local bfs   = component.proxy(computer.getBootAddress()) -- used only as a fallback in case of the FS driver crashing
local sched = scheduler

local drv_state = {}
local state = {}

local drv_env = setmetatable({--[[kernel = {},]] component = component, computer = computer}, {__index = function(tbl, k)
  if state[k] then
    tbl[k] = state[k]
    return state[k]
  else
    tbl[k] = _G[k]
    return _G[k]
  end
  return tbl[k]
end})

k.log("Driver auto-reload started")

function state.setStateEnv(k, v)
  checkArg(1, k, "string")
  checkArg(2, v, "string", "number", "table", "boolean", "function", "nil") -- I suppose we want to filter against threads (coroutines)
  local name = sched.info(sched.current()).name
  if not drv_state[name] then drv_state[name] = {} end
  drv_state[name][k] = v
end

function state.getStateEnv(k)
  checkArg(1, k, "string")
  local name = sched.info(sched.current()).name
  if not drv_state[name] then drv_state[name] = {} end
  local v = (drv_state[name][k] and drv_state[name][k]) or nil
  return v
end

function state.clearStateEnv()
  local name = sched.info(sched.current()).name
  drv_state[name] = {}
end

k.log("Loading driver configuration")

local configHandle, err = bfs.open("/l4/drv.cfg")
local drivers = { -- the default configuration
  "filesystem",
  "gpu",
  "keyboard",
  "term"
}
if configHandle then
  local tmp = bfs.read(configHandle, math.huge)
  bfs.close(configHandle)
  local ok, err = load("return " .. tmp, "=/l4/drv.cfg", "bt", {})
  if ok then
    local s, r = pcall(ok)
    if s then
      drivers = r
    end
  end
end

local handleDriverCrash = function(...)k.log(...)end

-- load drivers with the bootfs component; the FS driver has wither crashed or is not present yet
local function loadDriverBFS(name)
  local handle, err = bfs.open("/l4/drv/" .. name .. ".lua", "r")
  if not handle then
    return nil, err .. ": file not found"
  end
  local tmp = ""
  repeat
    local chunk = bfs.read(handle, math.huge)
    tmp = tmp .. (chunk or "")
  until not chunk
  bfs.close(handle)
  local ok, err = load(tmp, "=/l4/drv/" .. name, "bt", drv_env)
  if not ok then
    return nil, err
  end
  return spawn(ok, "drv/" .. name, function(err)handleDriverCrash(name, err)end)
end

-- load drivers with the FS driver
local function loadDriverDFS(name)
  local filehandle, err = ipcsend("drv/filesystem", "open", "/l4/drv/" .. name .. ".lua")
  if not filehandle then
    return nil, err .. ": file not found"
  end
  local filedata = filehandle:readAll()
  filehandle:close()
  local ok, err = load(filedata, "=/l4/drv/" .. name .. ".lua", "bt", drv_env)
  if not ok then
    return nil, err
  end
  return spawn(ok, "drv/" .. name, function(err)handleDriverCrash(name, err)end)
end

local function loadDriver(name)
  if sched.find("drv/filesystem") then
    return loadDriverDFS(name)
  else
    return loadDriverBFS(name)
  end
end

local function handleDriverCrash(driverHasCrashed, driverError)
  loadDriver(driverHasCrashed)
end

for i=1, #drivers, 1 do
  k.log("Load driver " .. drivers[i])
  local ok, err = loadDriver(drivers[i])
  if not ok then
    k.panic(err)
  end
end

while true do
  for i=1, #drivers, 1 do
    if not sched.find("drv/" .. drivers[i]) then
      loadDriver(drivers[i])
    end
  end
  coroutine.yield()
end
