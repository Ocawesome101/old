------------------------------- OpenNT pathlib.lua -----------------------------
-- Shared utilities for working with file paths.                              --
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

local plib = {}

local fs = require("fs")

function plib.localize(d)
  checkArg(1, d, "string")
  d = d:gsub("[/\\]+", "\\")
  if d:sub(1,1) ~= "/" and d:sub(1,1) ~= "\\" then
    d = fs.concat(os.getenv("CD"), d)
  end
  return d
end

function plib.resolve(p)
  local drv, path = p:match("^(.:)(.*)")
  local hax = not (drv and path)
  drv = drv or os.getenv("DRIVE") or "A:"
  path = path or (drv == os.getenv("DRIVE") and os.getenv("CD")) or "\\"
  if hax then path = fs.concat(path, p) end
  return drv, path
end

return plib
