-------------------------------- OpenNT edit.lua -------------------------------
-- A text editor. Weird, I know.                                              --
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

local cmd = require("cmdlib")
local plib = require("pathlib")
local fs = require("fs")
local gpu = require("component").gpu
local computer = require("computer")
local buf = {""}
local line = 1
local scroll = {
  w = 0,
  h = 0
}
local w, h = gpu.getResolution()
local args = cmd.parse(...)
local drv, fname

if args[1] then
  drv, fname = plib.resolve(args[1])
  local f = io.open(fs.concat(drv, fname))
  if not f then
    goto cont
  end
  buf = {}
  for line in f:lines("l") do
    buf[#buf + 1] = line
  end
  f:close()
else
  error("Missing file argument", 0)
end
::cont::

local bgcol = 0x000088
local fgcol = 0xAAAAAA
if gpu.getDepth() > 1 then
  gpu.setBackground(bgcol)
else
  bgcol = 0x000000
  gpu.setBackground(0x000000)  
end
gpu.setForeground(fgcol)
gpu.fill(1, 1, w, h, " ")
local cx, cy = 1, 2

local function checkCursor()
  if cy < 3 then
    if line > 1 then
      scroll.h = scroll.h - 1
      line = line - 1
      if cx > #buf[line] then cx = #buf[line] end
    else
      cy = 3
    end
  end
  if cy > h then
    if line <= #buf then
      scroll.h = scroll.h + 1
      cy = h
    else
      cy = h
    end
  end
end

gpu.setBackground(fgcol)
gpu.setForeground(0x000000)
gpu.fill(1, 1, w, 1, " ")
gpu.set(1, 1, "F1: Quit | F3: Save and Quit")
gpu.setBackground(bgcol)
gpu.setForeground(fgcol)
gpu.fill(1, 2, w, h - 1, "\u{2500}")
gpu.fill(1, 3, w, h - 2, "\u{2502}")
gpu.set(1, 2, "\u{250C}")
gpu.set(w, 2, "\u{2510}")
gpu.setBackground(fgcol)
gpu.setForeground(bgcol)
local drv, path = require("pathlib").resolve(fname)
gpu.set((w // 2 - #fname - 1), 2, " " .. fname:upper() .. " ")

local function draw()
  gpu.setBackground(bgcol)
  gpu.setForeground(fgcol)
  for i=1, h - 2, 1 do
    local set = (buf[i + scroll.h] or " "):sub(1 + scroll.w, 1 + scroll.w + w - 3):gsub("\n", "")
    set = set .. string.rep(" ", w - #set - 2)
    gpu.set(2, i + 2, set)
  end
  gpu.set(cx + 2, cy, "\u{2588}")
end

local handlers = {}
handlers[28] = function()
  if cx + scroll.w == #buf[line] then
    table.insert(buf, line + 1, "")
  else
    local ins = buf[line]:sub(cx + scroll.w + 1)
    buf[line] = buf[line]:sub(1, cx + scroll.w)
    table.insert(buf, line + 1, ins)
  end
  line = line + 1
  scroll.w = 0
  cx, cy = 1, cy + 1
end
handlers[200] = function() -- Up
  if line > 1 then cy = cy - 1 line = line - 1 end
end
handlers[208] = function() -- Down
  if line < #buf then cy = cy + 1 line = line + 1 end
end
handlers[203] = function() -- Left
  if cx > 1 then cx = cx - 1 end
  if cx == 1 and scroll.w > 0 then
    scroll.w = scroll.w - 1
  end
end
handlers[205] = function() -- Right
  if cx < w - 2 and cx + scroll.w < #buf[line] then cx = cx + 1 end
  if cx == w - 2 and cx + scroll.w <= #buf[line] then
    scroll.w = scroll.w + 1
  end
end
local run = true
handlers[59] = function() -- F1
  run = false
end
handlers[61] = function() -- F3
  run = false
  gpu.setBackground(0x000000)
  gpu.setForeground(0xFFFFFF)
  gpu.fill(1, 1, w, h, " ")
  local f, e = io.open(fs.concat(drv, fname), "w")
  if not f then
    error("Failed saving file: " .. e, 0)
  end
  f:write(table.concat(buf, "\n"))
  f:close()
end
handlers[14] = function() -- Backspace
  buf[line] = buf[line]:sub(1, cx + scroll.w - 1) .. buf[line]:sub(cx + scroll.w + 1)
  handlers[203]()
end

while run do
  checkCursor()
  draw()
  local sig, _, char, code = computer.pullSignal()
  if sig == "key_down" then
    if handlers[code] then
      handlers[code]()
    elseif char >= 32 and char < 127 then
      buf[line] = buf[line]:sub(1, cx + scroll.w) .. string.char(char) .. buf[line]:sub(cx + scroll.w + 1)
      handlers[205]()
    end
  end
end

gpu.setBackground(0x000000)
gpu.setForeground(0xFFFFFF)
gpu.fill(1, 1, w, h, " ")
