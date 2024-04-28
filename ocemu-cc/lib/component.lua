-- A fake-component library --

local component = {}

local computer_component = require("/lib/component_computer")
local gpu_component = require("/lib/component_gpu")
local fs_component = require("/lib/component_filesystem")

local addrPlex = {
  "0",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "a",
  "b",
  "c",
  "d",
  "e",
  "f"
}

local usedAddrs = {}

local function randomAddress() -- Get a random component address
  local rtn
  repeat
    rtn = ""
    repeat
      rtn = rtn .. addrPlex[math.random(1,15)]
    until #rtn == 32
    rtn = table.concat({rtn:sub(1,8),rtn:sub(9,13),rtn:sub(14,18),rtn:sub(19,23),rtn:sub(24,32)}, "-")
  until not usedAddrs[rtn]
  usedAddrs[rtn] = true
  return rtn
end

local function tcopy(tbl)
  local rtn = {}
  for k,v in pairs(tbl) do rtn[k] = v end
  return rtn
end

local emu_components = {
  {
    type = "computer",
    addr = randomAddress(),
    memory = 1024^2 -- There's no real memory limit
  },
  {
    type = "screen",
    addr = randomAddress()
  },
  {
    type = "gpu",
    addr = randomAddress(),
    tier = 3
  },
  {
    type = "eeprom",
    addr = randomAddress(),
    biosSize = 4096,
    dataSize = 256,
    label = "EEPROM (Lua BIOS)"
  },
  {
    type = "filesystem",
    addr = dofile("/lib/root_fs_address.lua"), -- Hax to pull off consistent rootFS addresses
    isTmp = false,
    label = "EmuRoot"
  },
  {
    type = "filesystem",
    addr = randomAddress(),
    isTmp = true,
    label = "tmpfs"
  },
  {
    type = "keyboard",
    addr = randomAddress()
  },
  {
    type = "internet",
    addr = randomAddress(),
    httpEnabled = true,
    tcpEnabled = false -- I don't know if CC:Tweaked supports TCP sockets
  }
}

if not fs.exists("/emudata/" .. emu_components[5].addr) then -- Create our rootfs dir
  fs.makeDir("/emudata/" .. emu_components[5].addr)
end

if not fs.exists("/emudata/tmpfs") then
  fs.makeDir("/emudata/tmpfs")
end

function component.list(ctype)
--  print("Getting component list of type " .. (ctype or "all"))
  local cList = {}
  for i=1, #emu_components, 1 do
    if emu_components[i].type == ctype or ctype == nil then
--      print("Found component " .. emu_components[i][2])
      cList[#cList + 1] = {type = emu_components[i].type, addr = emu_components[i].addr}
    end
  end
  local i = 1
  local rtn = {}
  local call = function()
    i = i + 1
--    print("Returning " .. (cList[i - 1] or "nil"))
    if cList[i - 1] then
      return (cList[i - 1].addr or nil), (cList[i - 1].type or nil)
    end
    return nil
  end
  for i=1, #cList, 1 do
    rtn[cList[i].addr] = cList[i].type
  end
  setmetatable(rtn, {__call=call})
  return rtn
end

function component.doc()
  return "This function is not implemented."
end

function component.fields()
  return "This function is not implemented."
end

local function fs_invoke(addr, operation, ...)
  local opArgs = {...}
--  print("Invoking " .. operation .. " " .. opArgs[1] .. " on filesystem " .. addr)
  if fs.exists("/emudata/" .. addr) then
    return fs_component[operation](...)
  else
    printError("No such component")
    return false, "No such component"
  end
end

local function gpu_invoke(addr, operation, ...)
  if not gpu_component.getScreen() and operation ~= "bind" then
    return false, "No screen bound"
  end
--  print("Executing operation " .. operation .. " on GPU " .. addr)
  return gpu_component[operation](...)
end

local function eeprom_invoke(addr, operation, ...)
--  print("Invoking " .. operation .. " on system EEPROM")
  local opArgs = {...}
  if fs.exists("/emudata/eeprom/") then
    if operation == "setData" then
      local handle = fs.open("/emudata/eeprom/data", "w")
      if string.len(opArgs[1]) <= 256 then
        handle.write(opArgs[1])
      else
        handle.close()
        return false, "Data too large"
      end
      handle.close()
    elseif operation == "getData" then
      local handle = fs.open("/emudata/eeprom/data", "r")
      local data = handle.readAll()
      handle.close()
      return data
    elseif operation == "set" then
      if string.len(opArgs[1]) <= 4096 then
        local handle = fs.open("/emudata/eeprom/bios.lua", "w")
        handle.write(opArgs[1])
        handle.close()
      else
        return false, "BIOS too large"
      end
    elseif operation == "get" then
      local handle = fs.open("/emudata/eeprom/bios.lua", "r")
      local data = handle.readAll()
      handle.close()
      return data
    elseif operation == "getDataSize" then
      return 256
    elseif operation == "getSize" then
      return 4096
    end
  else
    return false, "No such component"
  end
end

local function computer_invoke(addr, operation, ...)
  if computer[operation] then
--    print("Invoking operation " .. operation .. " on computer " .. addr)
    return computer[operation](...)
  end
end

function component.invoke(addr, operation, ...)
  local addr, ctype = addr, ""
  if not addr then
    return
  end
  for i=1, #emu_components, 1 do
    if emu_components[i].addr == addr then
      ctype = emu_components[i].type
      addr = emu_components[i].addr
    end
  end
  if not (ctype and addr) then
    return false, error("No such component")
  end
  if ctype == "filesystem" then
    return fs_invoke(addr, operation, ...)
  elseif ctype == "gpu" then
    return gpu_invoke(addr, operation, ...)
  elseif ctype == "computer" then
    return computer_invoke(addr, operation, ...)
  elseif ctype == "eeprom" then
    return eeprom_invoke(addr, operation, ...)
  else
    return false, error("Component " .. ctype .. " has not yet been implemented")
  end
end

function component.proxy(address)
  for i=1, #emu_components, 1 do
    if emu_components[i].addr == address then
      if emu_components[i].type == "filesystem" then
        local fs_component = require("/lib/component_filesystem")
        if emu_components[i].isTmp == true then
          fs_component.setAddress("tmpfs")
        else
          fs_component.setAddress(address)
        end
        fs_component.address = address
        fs_component.type = "filesystem"
        return tcopy(fs_component)
      elseif emu_components[i].type == "gpu" then
        gpu_component.address = address
        gpu_component.type = "gpu"
        return gpu_component
      elseif emu_components[i].type == "computer" then
        computer_component.type = "computer"
        computer_component.address = address
        return computer_component
      else
        return {type = emu_components[i].type, address = address}
      end
    end
  end
end

component.randomAddress = randomAddress

return component
