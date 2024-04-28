-- Can be flashed to a boot sector
local drive = computer.getBootAddress()
local data = ""
for i=2, 24, 1 do
  data = data .. component.invoke(drive, "readSector", i)
end
local ok, err = load(data, "=bootloader", "bt", _G)
if not ok then
  error(err)
end
ok()
