-- EEPROM with support for booting both managed and unmanaged drives. --

local boot_drives = {}
local boot_filesystems = {}

local eeprom = component.proxy(component.list("eeprom")())

local boot_addr = eeprom.getData()
function computer.getBootAddress()
  return boot_addr
end

function computer.setBootAddress(addr)
  boot_addr = addr
  eeprom.setData(addr)
end

for addr, _ in component.list("drive", true) do
  local ok, err = load(component.invoke(addr, "readSector", 1), "=drivescan", "bt", _G)
  if ok then
    table.insert(boot_drives, addr)
  end
end

for addr, _ in component.list("filesystem") do
  if component.invoke(addr, "exists", "/init.lua") then
    table.insert(boot_filesystems, addr)
  end
end

local function boot_unmanaged(drive)
  local sector = component.invoke(drive, "readSector", 1) -- Get the first sector from the drive
  local bootsector, err = load(sector, "=bootsector", "bt", _G) -- Load the sector but don't execute it; this is so we can catch errors
  if not bootsector then
    error(err)
  end
  computer.setBootAddress(drive)
  bootsector()
end

local function boot_managed(fs)
  local handle, reason = component.invoke(fs, "open", "/init.lua")
  if not handle then
    error(reason)
  end
  local buffer = ""
  repeat
    local data = component.invoke(fs, "read", handle, math.huge)
    buffer = buffer .. (data or "")
  until not data
  component.invoke(fs, "close", handle)
  local ok, err = load(buffer, "=/init.lua", "bt", _G)
  if not ok then
    error(err)
  end
  computer.setBootAddress(fs)
  ok()
end

if #boot_drives == 0 and #boot_filesystems == 0 then
  error("No bootable media found")
end

if #boot_drives == 1 and #boot_filesystems == 0 then
  boot_unmanaged(boot_drives[1])
end

if #boot_drives == 0 and #boot_filesystems == 1 then
  boot_managed(boot_filesystems[1])
end

local gpu, screen = component.list("gpu")(), component.list("screen")()
if gpu and screen then
  component.invoke(gpu, "bind", screen)
end
gpu = component.proxy(gpu)

gpu.set(1, 1, "Please select a boot device (default 1).")
local y = 2
for i=1, #boot_drives, 1 do
  gpu.set(1, y, tostring(y - 1) .. ". Unmanaged drive at " .. boot_drives[i]:sub(1,6))
  y = y + 1
end

for i=1, #boot_filesystems, 1 do
  gpu.set(1, y, tostring(y - 1) .. ". /init.lua from " .. boot_filesystems[i]:sub(1,6))
  y = y + 1
end

local choice = 1
while true do
  local e, _, id = computer.pullSignal(5) -- 5-second timeout

  if e then -- The user pressed a key
    if e == "key_down" then
      if tonumber(string.char(id)) <= #boot_drives + #boot_filesystems then
        choice = tonumber(string.char(id))
        break
      end
    end
  else -- The user didn't press a key
    break
  end
end

if choice <= #boot_drives then
  boot_unmanaged(boot_drives[choice])
else
  boot_managed(boot_filesystems[choice - #boot_drives])
end
