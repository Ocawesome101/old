------------------------ OpenNT kernel: 04_cfgsys.lua --------------------------
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
  local _REGISTRY = {}
  _REGISTRY.hkey_local_machine = {}
  _REGISTRY.hklm = _REGISTRY.hkey_local_machine
  _REGISTRY.hklm.system = nt.ex.cm.load("A:/NT/System32/Config/System.dat")
  _REGISTRY.hklm.software = nt.ex.cm.load("A:/NT/System32/Config/Software.dat")
  _REGISTRY.hkey_current_config = _REGISTRY.hklm.system.currentcontrolset["hardware profiles"].current
  _REGISTRY.hkcc = _REGISTRY.hkey_current_config

  local function reg_save()
    _REGISTRY.hklm.system:save("A:/NT/System32/Config/System.dat")
    _REGISTRY.hklm.software:save("A:/NT/System32/Config/Software.dat")
  end

  local api = {}
  function api.set(key, val)
    checkArg(1, key, "string")
    checkArg(2, val, "number", "string")
    key = key:lower()
    if type(val) == "string" then
      val = string.format("\"%s\"", val)
    end
    local cur = _REGISTRY
    local split = {}
    for seg in key:gmatch("[^\\/]+") do
      split[#split + 1] = tonumber(seg) or seg
    end
    for i=1, #split - 1, 1 do
      local seg = split[i]
      if cur[seg] then
        cur = cur[seg]
      else
        return nil, key .. ": registry key not found"
      end
    end
    cur[split[#split]] = val
    reg_save()
    return true
  end

  function api.create(key)
    checkArg(1, key, "string")
    key = key:lower()
    if api.get(key) then return true end
    local cur = _REGISTRY
    local split = {}
    for seg in key:gmatch("[^\\/]+") do
      split[#split + 1] = seg
    end
    for i=1, #split - 1, 1 do
      local seg = split[i]
      if cur[seg] then
        cur = cur[seg]
      else
        return nil, key .. ": registry key not found"
      end
    end
    cur[split[#split]] = {}
    reg_save()
    return true
  end

  function api.get(key)
    checkArg(1, key, "string")
    key = key:lower()
    local cur = _REGISTRY
    local split = {}
    for seg in key:gmatch("[^\\/]+") do
      split[#split + 1] = seg
    end
    for i=1, #split - 1, 1 do
      local seg = split[i]
      if cur[seg] then
        cur = cur[seg]
      else
        return nil, key .. ": registry key not found"
      end
    end
    return cur[split[#split]]
  end

  nt.win32.reg = api
end
