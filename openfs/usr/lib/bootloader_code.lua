-- OpenBootLoader
-- Main code
-- https://github.com/Ocawesome101/OpenBootLoader

local drive = component.proxy(computer.getBootAddress())
local gpu, screen = component.list("gpu")(), component.list("screen")()
local set = function()end
local log = function()end
if gpu and screen then
  gpu = component.proxy(gpu)
  gpu.bind(screen)
  set = gpu.set
  local y, w, h = 1, gpu.getResolution()
  gpu.fill(1, 1, w, h, " ")
  log = function(msg)
    set(1, y, msg)
    if y == h then
      gpu.copy(1, 1, w, h, 0, -1)
    else
      y = y + 1
    end
  end
end

if not string.unpack then
  computer.crash("OpenBootLoader requires Lua 5.3 or newer")
end

log("OpenBootLoader is starting...")

log("Initialize virtual components")
local create, remove
do
  local vcomponents = {}

  local list, invoke, proxy, comtype = component.list, component.invoke, component.proxy, component.type

  local ps = computer.pushSignal

  function create(componentAPI)
    checkArg(1, componentAPI, "table")
    vcomponents[componentAPI.address] = componentAPI
    ps("component_added", componentAPI.address, componentAPI.type)
  end

  function remove(addr)
    if vcomponents[addr] then
      ps("component_removed", vcomponents[addr].address, vcomponents[addr].type)
      vcomponents[addr] = nil
      return true
    end
    return false
  end

  function component.list(ctype, match)
    local matches = {}
    for k,v in pairs(vcomponents) do
      if v.type == ctype or not ctype then
        matches[v.address] = v.type
      end
    end
    local o = list(ctype, match)
    local i = 1
    local a = {}
    for k,v in pairs(matches) do
      a[#a+1] = k
    end
    for k,v in pairs(o) do
      a[#a+1] = k
    end
    local function c()
      if a[i] then
        i = i + 1
        return a[i - 1], (matches[a[i - 1]] or o[a[i - 1]])
      else
        return nil
      end
    end
    return setmetatable(matches, {__call = c})
  end

  function component.invoke(addr, operation, ...)
    checkArg(1, addr, "string")
    checkArg(2, operation, "string")
    if vcomponents[addr] then
--      kernel.log("vcomponent: " .. addr .. " " .. operation)
      if vcomponents[addr][operation] then
        return vcomponents[addr][operation](...)
      end
    end
    return invoke(addr, operation, ...)
  end

  function component.proxy(addr)
    checkArg(1, addr, "string")
    if vcomponents[addr] then
      return vcomponents[addr]
    else
      return proxy(addr)
    end
  end

  function component.type(addr)
    checkArg(1, addr, "string")
    if vcomponents[addr] then
      return vcomponents[addr].type
    else
      return comtype(addr)
    end
  end
end

log("Initializing Bootloader Read-Only FS driver")

-- BROFS driver. Used to load other drivers. --
local brofs_part = {}
local ptable = {}

log("Scanning partition table")
do
  local _ptable = drive.readSector(25)
  local ptable = {}
  for i=1, #_ptable, 64 do
    local part = _ptable:sub(i, i + 63)
    local pstart, pend, ptype, pflags, guid, label = string.unpack("<I4I4c8I4c8c36", part)
    if guid:sub(1,1):byte() == 0 then
      break
    end
    if ptype:find("BROFS") then
      brofs_part = {
        Start = pstart,
        End = pend,
        Type = ptype,
        Flags = pflags,
        GUID = guid,
        Label = label
      }
    end
    ptable[#ptable + 1] = {
      Start = pstart,
      End = pend,
      Type = ptype,
      Flags = pflags,
      GUID = guid,
      Label = label
    }
  end
end

log("Reading BROFS inode data")
local brotableRaw = drive.readSector(brofs_part.Start) .. drive.readSector(brofs_part.Start + 1)
local inodes = {}
for i=1, 32, 1 do
  local n = (i - 1) * 32
  if n == 0 then n = 1 end
  local entry = brotableRaw:sub(n, n + 32)
  local start, size, max, flags, _, name = string.unpack("I2I2I2I1I1c24", entry)
  name = name:gsub(" ", "")
  inodes[name] = {
    start = start,
    size = size
  }
end

local function readSectors(start, n)
  local d = ""
  for i=start, n, 1 do
    d = d .. drive.readSector(i)
  end
  return d
end

function fread(file)
  if not inodes[file] then
    return nil, "no such file"
  end
  local inode = inodes[file]
  local fdata = readSectors(inode.start, math.ceil(inode.size/512))
  return fdata:sub(1, inode.size)
end

log("Reading boot.cfg")
local bcfg = fread("boot.cfg")

local config = {
  OPENFS = "OpFS.lua",
}
if bcfg then
  local ok, err = load("return " .. bcfg, "=/brofs/boot.cfg", "bt", {})
  if ok then
    local s, r = pcall(ok)
    if s then
      config = r
    end
  end
end

local fs = {}

for i=1, #ptable, 1 do
  local t = ptable[i].Type:gsub(" ","")
  if config[t] then
    fs[#fs + 1] = {
      driver = config[t],
      entry = ptable[i]
    }
  end
end

local function boot(pdata)
  local driver = pdata.driver
  pdata = pdata.entry
  local drvdata, err = fread(driver)
  if not drvdata then
    log("failed loading driver " .. driver .. ": " .. err)
    return
  end
  local ok, err = load(drvdata, "=/brofs/" .. driver, "bt", _G)
end

if #fs == 1 then
  boot(fs[1])
else
  log("Please select a filesystem (default 1)")
  for i=1, #fs, 1 do
    log(i .. ": " .. fs[i].entry.Label .. "(driver " .. fs[i].driver .. ")")
  end
  local max = computer.uptime() + 5
  local n = 1
  local t
  repeat
    local e, _, id = computer.pullSignal(max - computer.uptime())
    if e == "key_down" then
      t = tonumber(string.char(id))
      if t and fs[t] then n = t; break end
    end
  until max <= computer.uptime() or (t and fs[t])
  boot(fs[n])
end

while true do
  computer.pullSignal()
end
