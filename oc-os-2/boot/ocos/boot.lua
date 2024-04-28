local args = {...}
local osDir = "/ocos/" or args[1]

print("Welcome to OC-OS!")

loadfile(osDir .. "boot.lua")(osDir)
