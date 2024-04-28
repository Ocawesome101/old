-- init.lua: API-dependent! --

local invoke, addr = component.invoke
if computer.getBootAddress then
  addr = computer.getBootAddress()
else
  local eeprom = component.list("eeprom", true)()
  local data = invoke(eeprom, "getData")
  if type(data) == "string" and #data == 36 and not data:find("^[%w%-]") then
    addr = data
  else
    repeat
      addr = component.list("filesystem", true)()
    until addr ~= computer.tmpAddress()
  end
end

local function loadfile(file)
  local handle, err = invoke(addr, "open", file, "r")
  if not handle then
    return nil, err
  end
  local data = ""
  repeat
    local chunk = invoke(addr, "read", handle, math.huge)
    data = data .. (chunk or "")
  until not chunk
  invoke(addr, "close", handle)
  return load(data, "="..file, "bt", _G)
end

local ok, err = loadfile("/system101/boot/kernel.lua")
if not ok then
  error(err)
end

local status, msg = xpcall(ok, debug.traceback, loadfile, addr)
if not status and msg then
  error(msg)
end
