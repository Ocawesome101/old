----------------------------- OpenNT Boot Manager ------------------------------
-- Copyright (C) 2020 Ocawesome101                                            --
--                                                                            --
-- This program is free software: you can redistribute it and/or modify       --
-- it under the terms of the GNU General Public License as published by       --
-- the Free Software Foundation, either version 3 of the License, or          --
-- (at your option) any later version.                                        --
--                                                                            --
-- This program is distributed in the hope that it will be useful,            --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of             --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              --
-- GNU General Public License for more details.                               --
--                                                                            --
-- You should have received a copy of the GNU General Public License          --
-- along with this program.  If not, see <https://www.gnu.org/licenses/>.     --
--------------------------------------------------------------------------------

local name = "OpenNT Boot Manager"

local errmsg = [[
OpenNT failed to start. A recent hardware or soft-
ware change might be the cause. To fix the        
problem, contact your hardware manufacturer or    
system administrator for assistance.              
                                                  
Info:                                             
]]

local rootfs = component.proxy(...)

local function read_file(file)
  local handle = assert(rootfs.open(file))
  local data = ""
  repeat
    local chunk = rootfs.read(handle, math.huge)
    data = data .. (chunk or "")
  until not chunk
  rootfs.close(handle)
  return data
end

local bcd
if rootfs.exists("/boot/bcd") then
  local ok, err = load("return " .. read_file("/boot/bcd"))
  if not ok then
    error("failed loading BCD: " .. err)
  end
  bcd = ok()
else
  bcd = {
    {
      name = "OpenNT",
      file = "/boot/ntoskrnl.lua",
      args = {
        log = true,
        services = true,
        multiuser = true
      }
    }
  }
end

local gpu = component.proxy(component.list("gpu")())
local screen = component.list("screen")()
gpu.bind(screen)
local w,h=gpu.maxResolution()
gpu.setResolution(w,h)
local menu = {}
gpu.fill(1,1,w,h," ")
gpu.set(1,3,"Choose an operating system to start:")
local function draw_menu()
  gpu.setForeground(0x000000)
  gpu.setBackground(0xbebebe)
  gpu.fill(1,1,w,1," ")
  gpu.set((w // 2) - 10, 1, name)
  for i=1, #menu, 1 do
    if menu[i].selected then
      gpu.setForeground(0x000000)
      gpu.setBackground(0xbebebe)
    else
      gpu.setForeground(0xFFFFFF)
      gpu.setBackground(0x000000)
    end
    gpu.set(2, 4+i, menu[i].text .. (" "):rep((w-4) - #menu[i].text))
  end
end

for i=1, #bcd, 1 do
  menu[i] = {
    selected = false,
    text = bcd[i].name
  }
end

menu[1].selected = true

local sel = 1
local acts = {
  [13] = function()
    local ok, ret, err = pcall(read_file, bcd[sel].file)
    if ok then
      ok, err = load(ret, "="..bcd[sel].file)
    end
    if not ok then
      gpu.setForeground(0xFFFFFF)
      gpu.setBackground(0x000000)
      local i = 1
      for line in (errmsg .. err):gsub("\t", "  "):gmatch("[^\n]+") do
        gpu.set(1, i + 2, line)
        i = i + 1
      end
      while true do computer.pullSignal() end
    end
    gpu.setForeground(0x000000)
    gpu.setBackground(0x000000)
    gpu.fill(1, 1, w, h, " ")
    gpu.setForeground(0x000000)
    gpu.setBackground(0xbebebe)
    local msg = bcd[sel].message or string.format("Starting %s...", bcd[sel].name)
    gpu.fill(1, h, w, 1, " ")
    gpu.set((w // 2) - (#msg // 2), h, msg)
    local ok, err = xpcall(ok, debug.traceback, bcd[sel].args)
    if not ok then
      gpu.setForeground(0xFFFFFF)
      gpu.setBackground(0x000000)
      local i = 1
      for line in (errmsg .. err):gsub("\t", "  "):gmatch("[^\n]+") do
        gpu.set(1, i + 2, line)
        i = i + 1
      end
      while true do computer.pullSignal() end
    end
  end,
  [200] = function()
    if sel > 1 then
      menu[sel].selected = false
      sel = sel - 1
      menu[sel].selected = true
    end
  end,
  [208] = function()
    if sel < #menu then
      menu[sel].selected = false
      sel = sel + 1
      menu[sel].selected = true
    end
  end
}

if #bcd == 1 then
  acts[13]()
end

local max = computer.uptime() + (bcd.timeout or 5)
while true do
  draw_menu()
  if max < math.huge then gpu.set(1, h, "Starting selected in " .. (max - computer.uptime()) // 1 .. "s") end
  local sig, _, char, key = computer.pullSignal(math.min(1, max - computer.uptime()))
  if sig == "key_down" then
    if acts[char] then
      acts[char]()
    elseif acts[key] then
      acts[key]()
    end
  elseif computer.uptime() >= max then
    acts[13]()
  end
end
