-------------------------------- OpenNT type.lua -------------------------------
-- NT version of cat. Why not just cat?                                       --
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

local fs = require("fs")

local args = {...}

local drv, path = require("pathlib").resolve(args[1])

local handle = io.open(fs.concat(drv, path))
if not handle then
  error("Invalid file", 0)
end

for line in handle:lines() do print(line) end

handle:close()
