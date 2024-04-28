-- OC Init System --
local loadfile = ...

print("Boot stage 2: Load modules")
os.run("/sys/core/load_modules.lua")()
print("Boot stage 3: Load OS interfacing utilities")
_G.shell = os.run("/sys/apis/shell.lua")() 
print("Launching login screen")
os.run("/programs/login.lua")()
