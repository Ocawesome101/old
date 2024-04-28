------------------------- OpenNT kernel: 01_ntutil.lua -------------------------
-- Some utility functions.                                                    --
--                                                                            --
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

do
  local fs = nt.ke.fs

  function nt.ke.tcopy(tbl)
    local seen = {}
    local function copy(t, to)
      to = to or {}
      for k, v in pairs(t) do
        if type(v) == "table" then
          if not seen[v] then
            seen[v] = {}
            to[k] = seen[v]
            copy(v, seen[v])
          end
        else
          to[k] = v
        end
      end
      return to
    end
    return copy(tbl)
  end

  function nt.ke.readfile(file)
    local handle = assert((fs.open(file)), file .. ": file not found")
    local data = ""
    repeat
      local chunk = handle:read(math.huge)
      data = data .. (chunk or "")
    until not chunk
    handle:close()
    return data
  end

  function nt.ke.serialize(tbl)
    checkArg(1, tbl, "table")
    local seen = {}
    local function sr(t)
      local r = "{"
      for k, v in pairs(t) do
        if type(v) == "table" then
          if seen[v] then
            v = "<recursion>"
          else
            seen[v] = true
            v = sr(v)
          end
        elseif type(v) == "string" then
          v = string.format('"%s"', v)
        elseif type(v) == "function" or type(v) == "thread" then
          error("function / thread cannot be serialized")
        end
        if type(k) == "string" then
          k = string.format("\"%s\"", k)
        end
        local ent = string.format("[%s]=%s,", k, v)
        r = r .. ent
      end
      r = r .. "}"
      return r
    end
    return sr(tbl)
  end
end
