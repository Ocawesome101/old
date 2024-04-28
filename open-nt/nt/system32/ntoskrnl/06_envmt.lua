---------------------- OpenNT Kernel: 13_environment.lua -----------------------
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
  local global_env = {}
  function os.setenv(k, v)
    checkArg(1, k, "string", "number")
    if type(k) == "string" then k = k:lower() end
    (nt.ex.ps.info() or {data = {env = global_env}}).data.env[k] = v
  end
  
  function os.getenv(k)
    checkArg(1, k, "string", "number")
    if type(k) == "string" then k = k:lower() end
    return (nt.ex.ps.info() or {data = {env = global_env}}).data.env[k]
  end
end
