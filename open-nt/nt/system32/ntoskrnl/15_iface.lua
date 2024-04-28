---------------------- OpenNT Kernel: 05_interface.lua -------------------------
-- Load and execute interfaces based on BCD.                                  --
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

  nt.ki.log("Interface: loaded")
  
  local function exec_files(path)
    nt.ki.log("Running files from " .. path)
    local files = fs.list(path)
    table.sort(files)
    for k, file in ipairs(files) do
      nt.ki.log("Interface: " .. file)
      assert(loadfile(path .. file, nil, nt.ki.sandbox))()
    end
  end

  if fs.exists("A:/NT/System32/" .. nt.ki.flags.interface) then
    nt.ki.flags.log = false
    exec_files("A:/NT/System32/" .. nt.ki.flags.interface .. "/")
  else
    nt.ki.panic("Interface A:/NT/System32/" .. nt.ki.flags.interface .. " nonexistent")
  end
  nt.ki.log("Interface: Done.")
  nt.ex.ps.start()
end
