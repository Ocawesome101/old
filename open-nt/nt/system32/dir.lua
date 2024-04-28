-------------------------------- OpenNT dir.lua --------------------------------
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
local fs = require("fs")
local pl = require("pathlib")

local args, opts = cmd.parse(...)

if #args == 0 then
  args[1] = "\\"
end

local drv, path = pl.resolve(args[1] or "\\")
local prx = assert(fs.get(drv))

print(string.format("\n\tVolume in drive %s is %s", drv:upper(), prx.getLabel() or prx.address:sub(1,3)))
print(string.format("\tVolume Serial Number is %s", prx.address:sub(1, 13):upper()))
print(string.format("\tDirectory of %s", fs.concat(drv:upper(), path:upper())))
io.write("\n")

local function lastModified(f)
  local full = fs.concat(drv, path, f)
  local lm = fs.lastModified(full)
  return os.date("%x %r", lm)
end

local fullpath = fs.concat(drv, path)
if not fs.exists(fullpath) then
  error("File not found", 0)
elseif not fs.isDirectory(fullpath) then
  error("Invalid directory", 0)
end

local files = fs.list(fullpath)
if not files then
  error("File not found", 0)
end
table.sort(files)
local maxlen = 0
for i=1, #files, 1 do
  if #files[i] > maxlen then
    maxlen = #files[i]
  end
end

local function pad(s, l)
  return s .. (" "):rep(l - #s)
end

maxlen = maxlen + 5
for i=1, #files, 1 do
  local name, ext = files[i]:match("(.+)%.(.+)")
  name = name or files[i]
  ext = ext or fs.isDirectory(fs.concat(drv, path, files[i])) and "<DIR>" or ""
  files[i] = (string.format("%s%s  %s", pad(name:upper(), maxlen), pad(ext:upper(), 6), lastModified(files[i])))
end

local w, h = require("component").gpu.getResolution()
local printed = 4
for i=1, #files, 1 do
  printed = printed + 1
  print(files[i])
  if opts.p and printed == h - 1 then
    io.write("Press any key to continue...")
    repeat
      local sig, _, char = coroutine.yield()
    until sig == "key_down"
    printed = 1
    io.write("\n\n(Continuing " .. fs.concat(drv, path):upper() .. ")\n")
  end
end

print(string.format("\t%d file(s)", #files))
