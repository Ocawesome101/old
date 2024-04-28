-------------------------------- OpenNT label.lua ------------------------------
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
local args, opts = cmd.parse(...)

if #args == 0 then
  args[1] = os.getenv("DRIVE")
end

local drv = args[1] or os.getenv("DRIVE")
local prx = assert(fs.get(args[1]))

print(string.format("Volume in drive %s is %s", drv, prx.getLabel() or prx.address:sub(1,3)))
print(string.format("Volume serial number is %s", prx.address:sub(1,13)))
local label
if not args[2] then
  io.write("Volume label (36 characters, ENTER for none)? ")
  local data = io.read():gsub("\n", "")
  if #data == 0 then
    io.write("\nDelete current volume label (Y/N)? ")
    local inp = io.read():gsub("\n", ""):lower()
    if inp == "y" then
      print("\nVolume label cleared")
      prx.setLabel(nil)
    end
    return
  else
    label = data
  end
else
  label = args[2]
end
prx.setLabel(label)
print("\nVolume label set to " .. label)
