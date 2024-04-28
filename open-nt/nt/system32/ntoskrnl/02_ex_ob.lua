-------------------- OpenNT kernel: 02_executive_objman.lua --------------------
-- OpenNT implementation of the Windows NT Executive's Object Manager.        --
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
  local obj = {}

  function obj.new(typ)
    local n = {}
    local ts = tostring(n):gsub("table", typ)
    return setmetatable(n, {__index = obj, __type = typ, __tostring = function() return ts end})
  end

  function obj:clone()
    local cp = nt.ke.tcopy(self)
    local mt = nt.ke.tcopy(getmetatable(self))
    local ts = tostring(cp):gsub("table", mt.__type)
    mt.__tostring = function()
      return ts
    end
    return setmetatable(cp, mt)
  end

  nt.ex.ob = obj
end
