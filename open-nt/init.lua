------------------------------- OpenNT init.lua --------------------------------
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

local addr, invoke = computer.getBootAddress(), component.invoke

local kernelPath = "/boot/bootmgr.lua"

local handle, err = invoke(addr, "open", kernelPath)
if not handle then
  error(err)
end

local t = ""
repeat
  local c = invoke(addr, "read", handle, math.huge)
  t = t .. (c or "")
until not c

invoke(addr, "close", handle)

local ok, err = load(t, "=bootmgr", "bt", _G)
if not ok then
  kernel.logger.panic(err)
end

local ok, err = xpcall(ok, debug.traceback, addr)
if not ok and err then
  error(err)
end
