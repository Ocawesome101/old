--------------------------------- OpenNT svc.lua -------------------------------
-- Service management library.                                                --
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

local ps = require("ex.ps")
local fs = require("fs")

local svc = {}
local running = {}

local dir = os.getenv("SVCDIR") or "A:/NT/System32/Services/"

function svc.start(sv, iscmd)
  checkArg(1, sv, "string")
  checkArg(2, iscmd, "boolean", "nil")
  if iscmd and running[sv] then
    error("Service is already running", 0)
  else
    if running[sv] then return true end
    local exec = assert(loadfile((fs.concat(dir, sv .. ".lua"))))
    running[exec] = ps.spawn(exec, sv)
    return true
  end
end

function svc.stop(sv, iscmd)
  checkArg(1, sv, "string")
  checkArg(2, iscmd, "boolean", "nil")
  if not running[sv] then
    if iscmd then
      error("Service is not running", 0)
    else
      return true
    end
  else
    local ok, err = ps.kill(running[sv])
    if not ok then
      error(err, 0)
    end
    return true
  end
end

function svc.running(_, iscmd)
  checkArg(2, iscmd, "boolean", "nil")
  local ret = {}
  for k,v in pairs(running) do
    ret[k] = true
  end
  if iscmd then
    print("Pid  Name")
    print("---  -----")
    for k, v in pairs(ret) do
      print(string.format("%3d  %s", running[k], k))
    end
  else
    return ret
  end
end

return svc
