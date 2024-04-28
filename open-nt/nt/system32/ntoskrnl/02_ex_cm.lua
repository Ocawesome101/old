-------------------- OpenNT kernel: 02_executive_confman.lua -------------------
-- OpenNT implementation of the Configuration Manager from Windows NT.        --
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

  local config = {}

  -- load configuration in registry format
  function config.load(file)
    checkArg(1, file, "string")
    local c = assert(assert(load("return " .. nt.ke.readfile(file), "=_reg_load"))())
    local ts = tostring(c):gsub("table", "registry")
    return setmetatable(c, {__index = config, __type = "registry", __tostring = function() return ts end})
  end

  function config:save(file)
    checkArg(1, file, "string")
    local s = nt.ke.serialize(self)
    local h = fs.open(file, "w")
    h:write(s)
    h:close()
    return true
  end

  nt.ex.cm = config
end
