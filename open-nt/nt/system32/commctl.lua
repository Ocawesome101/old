-------------------------- OpenNT Shell32: commctl.lua -------------------------
-- The Common Control Library.                                                --
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

local ccl = {}
local gdi = require("win32").gdi

-- Create a window object
function ccl.window(w, h)
  local surface = gdi.createContext(gdi.HW_WO_PERSIST, w, h)
  local win = {}
  win.canvas = surface
  function win.redraw(x, y)
    win.canvas:blit(x, y)
  end
  nt.win32.dwm.addWindow(win)
  return win
end

return ccl
