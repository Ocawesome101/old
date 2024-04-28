--------------------------- OpenNT explorer.lua --------------------------------
-- The heart and soul of the OpenNT desktop.                                  --
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

local win32 = require("win32")
local ps = require("ex.ps")
if not win32.gdi then
  error("This program requires graphical mode.", 0)
end

-- DWM API: win32.dwm
-- Taskbar API: shell.taskbar
local run = {
  dwm = {
    pid = 0,
    name = "Desktop Window Manager",
    file = "A:/NT/System32/dwm.lua"
  },
  taskbar = {
    pid = 0,
    name = "Desktop Task Bar",
    file = "A:/NT/System32/Taskbar.lua"
  }
}

while true do
  for k, v in pairs(run) do
    if not ps.running(run[k].pid) then
      run[k].pid = ps.spawn(loadfile(run[k].file), run[k].name)
    end
  end
end
