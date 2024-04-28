-------------------------------- OpenNT mem.lua --------------------------------
-- Print memory information.                                                  --
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
local computer = require("computer")
local args, opts = cmd.parse(...)
if opts.g then
  print("Collecting garbage")
  for i=1, 10, 1 do
    coroutine.yield(0)
  end
  return
end

local total, free = computer.totalMemory(), computer.freeMemory()
local used = total - free
total, free, used = total // 1024, free // 1024, used // 1024

print([[
Memory Type       Total  =   Used  +   Free
---------------  -------   -------    ------]])

print(string.format("Conventional     %6dK   %6dK   %6dK", total, used, free))
print("---------------  -------   -------    ------")
print(string.format("Total Memory     %6dK   %6dK   %6dK\n", total, used, free))
print("Note: Only limited memory info is available.")
