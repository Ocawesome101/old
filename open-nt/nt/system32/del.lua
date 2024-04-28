-------------------------------- OpenNT del.lua --------------------------------
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
local pl = require("pathlib")
local fs = require("fs")

local args, opts = cmd.parse(...)

if #args == 0 then
  error("Required parameter missing", 0)
end

local drv, path = pl.resolve(args[1])
local full = fs.concat(drv, path)

if not fs.exists(full) then
  error("File not found", 0)
end

if opts.P or opts.p then
  io.write(args[1] .. ", Delete (Y/N)? ")
  while true do
    local s = io.read():gsub("\n", "")
    if s:upper() == "N" then
      return
    elseif s:upper() == "Y" then
      break
    end
  end
end

local ok, err = fs.remove(full)
if not ok then
  error(err, 0)
end
