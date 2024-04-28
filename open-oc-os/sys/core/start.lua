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
local __screenRaw = component.list("screen", true)()
local __gpuRaw = __screenRaw and component.list("gpu", true)()

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
loadfile("/sys/apis/os.lua")(loadfile)
os.status("Welcome to " .. _os_version)
os.status("Boot stage 1: Initialize system")
loadfile("/sys/apis/filesystem.lua")()
os.status("Mounting root filesystem")
fs.mount(computer.getBootAddress,"/")
loadfile("/sys/apis/io.lua")()
print("Loaded /sys/apis/io.lua")
print("Loading ocinit")
loadfile("/sys/core/ocinit.lua")(loadfile)
