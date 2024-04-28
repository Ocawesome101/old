------------------------- OpenNT kernel: 11_sbcomp.lua -------------------------
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
  local overrides = {
    gpu = nt.ki.gpu,
    screen = component.proxy(nt.ki.gpu.getScreen())
  }
  local function get(_, t)
    if overrides[t] then
      return overrides[t]
    else
      return component.proxy((component.list(t)()))
    end
  end

  setmetatable(nt.ki.sandbox.package.loaded.component, {__index = get})
end
