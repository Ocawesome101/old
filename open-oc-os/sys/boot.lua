-- Boot OC-OS --

local loadfile = ...

_G.beep = computer.beep

_G.__invoke = component.invoke

_G.filesystems = {}
_G._os_version = "OC-OS 0.22"

for addr, ctype in component.list() do
  if ctype == "filesystem" then
    table.insert(_G.filesystems, addr)
  elseif ctype == "keyboard" then
    _G.__keyboard = addr
  end
end

-- The following thirteen lines are ripped straight from OpenOS.
local w, h
_G.__screenRaw = component.list("screen", true)()
_G.__gpuRaw = __screenRaw and component.list("gpu", true)()

_G.gpu = component.proxy(__gpuRaw)
if not gpu.getScreen() then
  gpu.bind(__screenRaw)
end
_G.__screen = component.proxy(gpu.getScreen())
w, h = gpu.maxResolution()
gpu.setResolution(w, h)
gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")

-- Load APIs
loadfile("/apis/os.lua")(loadfile)
os.status("Boot stage 1: Initialize system")
loadfile("/apis/filesystem.lua")()
os.status("Mounting root filesystem")
fs.mount(computer.getBootAddress,"/")
loadfile("/apis/io.lua")()
print("Boot stage 1: Initialize system")
print("Mounting root filesystem")
print("Loaded /apis/io.lua")
loadfile("/apis/graphics.lua")()
print("Loaded /apis/graphics.lua")
print("Boot stage 2: Load modules")
os.run("/sys/core/load_modules.lua")()
print("Boot stage 3: Load OS interfacing utilities")
os.run("/sys/core/shell_api.lua")()
