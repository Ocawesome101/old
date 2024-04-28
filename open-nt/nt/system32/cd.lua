--------------------------------- OpenNT cd.lua --------------------------------
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

local plib = require("pathlib")
local fs = require("fs")
local args = {...}

if #args == 0 then
  print(os.getenv("DRIVE") .. os.getenv("CD"):upper():gsub("[/\\]+", "\\"))
  return
end

local hax = args[1]:match("^(.:)$")
if hax then
  if hax == os.getenv("DRIVE") then
    os.setenv("CD", "\\")
    return
  end
end

local drv, path = plib.resolve(args[1])

local d = fs.concat(drv, path)

if fs.exists(d) and fs.isDirectory(d) then
  os.setenv("CD", path)
else
  error(d .. ": Invalid directory", 0)
end
