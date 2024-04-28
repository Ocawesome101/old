-------------------------------- OpenNT kernel ---------------------------------
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

local flags = ... or {}
flags.interface = flags.interface or "cmd"
flags.log = flags.log ~= false
flags.services = flags.services ~= false
flags.multiuser = flags.multiuser ~= false

_G.nt = {} -- the kernel API
nt.ki = {flags = flags}
nt.ke = {}

nt.ki.gpu = component.proxy(component.list("gpu")())
nt.ki.gpu.bind((component.list("screen")()))

do
  local bsodtext = [[
A problem has been detected and OpenNT has been
shut down to prevent damage to your computer.

The problem seems to be caused by the following
error:
]]

  local function bsod(err)
    computer.beep()
    local panic = bsodtext .. err
    nt.ki.gpu.setForeground(0xFFFFFF)
    nt.ki.gpu.setBackground(nt.ki.gpu.getDepth() > 1 and 0x0066FF or 0x000000)
    local w, h = nt.ki.gpu.maxResolution()
    nt.ki.gpu.setResolution(w, h)
    nt.ki.gpu.fill(1, 1, w, h, " ")
    local y = 1
    for line in panic:gmatch("[^\n]+") do
      nt.ki.gpu.set(1, y, (line:gsub("\t", "  ")))
      y = y + 1
    end
    while true do
      computer.pullSignal()
    end
  end

  nt.ki.panic = bsod
end

-- wrap most kernel code in a pcall
local ok, err = xpcall(function()

_G._OSVERSION = "OpenNT 0.5"

-- kernel logger
do
  local y = 0
  local bmsg = "Starting OpenNT..."
  local w, h = nt.ki.gpu.maxResolution()
  if not nt.ki.flags.log then
    nt.ki.gpu.fill(1, 1, w, h, " ")
    nt.ki.gpu.set(1, 1, bmsg)
    goto cont
  end
  nt.ki.gpu.setForeground(0xFFFFFF)
  nt.ki.gpu.setBackground(0x000000)
  nt.ki.gpu.fill(1, 1, w, h, " ")
  nt.ki.gpu.setForeground(0x000000)
  nt.ki.gpu.setBackground(0xbebebe)
  nt.ki.gpu.fill(1, h, w, 1, " ")
  nt.ki.gpu.set((w // 2) - (#bmsg // 2), h, bmsg)
  nt.ki.gpu.setForeground(0xFFFFFF)
  nt.ki.gpu.setBackground(0x000000)
  ::cont::
  function nt.ki.log(msg)
    if not flags.log then return end
    for line in msg:gmatch("[^\n]+") do
      nt.ki.gpu.setForeground(0xFFFFFF)
      nt.ki.gpu.setBackground(0x000000)
      if y > h - 2 then
        y = h - 1
        nt.ki.gpu.copy(1, 1, w, h - 1, 0, -1)
        nt.ki.gpu.fill(1, h - 1, w, 1, " ")
      else
        y = y + 1
      end
      nt.ki.gpu.setForeground(0xFFFFFF)
      nt.ki.gpu.setBackground(0x000000)
      nt.ki.gpu.set(1, y, (line:gsub("\t", "  ")))
      nt.ki.gpu.setForeground(0x000000)
      nt.ki.gpu.setBackground(0xBEBEBE)
      nt.ki.gpu.set(1, h, string.format("%dK free  ", computer.freeMemory() // 1024))
    end
  end
end

-- base boot-utils, overwritten later
nt.ki.log("Stage 1: early boot")

nt.ki.log("Getting proxy for drive A:/")
local addr = computer.getBootAddress()
local A = component.proxy(addr)

nt.ki.log("Initializing boot utilities")
local function read_file(file)
  local handle = assert(A.open(file))
  local data = ""
  repeat
    local chunk = A.read(handle, math.huge)
    data = data .. (chunk or "")
  until not chunk
  A.close(handle)
  return data
end

function loadfile(file, mode, env)
  local data = read_file(file)
  return load(data, "=" .. file, mode or "bt", env or _G)
end

local function run_file(f,...)
  return assert(loadfile(f))(...)
end

local function run_files(dir, log)
  log = log or nt.ki.log
  local files = A.list(dir)
  table.sort(files)
  for _, file in ipairs(files) do
    log(file)
    run_file(dir .. "/" .. file)
  end
end

nt.ki.log("Loading base kernel")
run_files("/nt/system32/ntoskrnl", function(n) nt.ki.log("Run file: " .. n:match("%d%d_(.+)%.lua")) end)

end, debug.traceback) -- kernel code ends here

if not ok then
  nt.ki.panic(err)
end

while true do computer.pullSignal() end
